require "net/http"
require "json"
require "rexml/document"

class NewsFetcherService
  NAVER_KEYWORDS = ["가톨릭 성단", "성산포 성당", "제주교구", "가톨릭 미사"].freeze
  CATHOLIC_RSS_URL = "https://www.catholicnews.co.kr/news/rss.php".freeze
  DIOCESE_RSS_URL = "https://www.jejucatholic.org/rss".freeze

  def self.fetch_all(parish)
    results = { naver: 0, catholic_news: 0, diocese: 0, errors: [] }

    results[:naver] = fetch_naver(parish, results[:errors])
    results[:catholic_news] = fetch_rss(parish, "catholic_news", CATHOLIC_RSS_URL, results[:errors])
    results[:diocese] = fetch_rss(parish, "diocese", DIOCESE_RSS_URL, results[:errors])

    results
  end

  private

  def self.fetch_naver(parish, errors)
    client_id = ENV["NAVER_CLIENT_ID"]
    client_secret = ENV["NAVER_CLIENT_SECRET"]

    unless client_id.present? && client_secret.present?
      errors << "네이버 API 키가 설정되지 않았습니다 (NAVER_CLIENT_ID, NAVER_CLIENT_SECRET)"
      return 0
    end

    count = 0
    NAVER_KEYWORDS.each do |keyword|
      begin
        uri = URI("https://openapi.naver.com/v1/search/news.json")
        uri.query = URI.encode_www_form(query: keyword, display: 10, sort: "date")

        request = Net::HTTP::Get.new(uri)
        request["X-Naver-Client-Id"] = client_id
        request["X-Naver-Client-Secret"] = client_secret

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 10) do |http|
          http.request(request)
        end

        next unless response.is_a?(Net::HTTPSuccess)

        data = JSON.parse(response.body)
        (data["items"] || []).each do |item|
          ext_id = Digest::MD5.hexdigest(item["link"])
          next if NewsArticle.unscoped.exists?(external_id: ext_id)

          NewsArticle.create!(
            parish: parish,
            title: strip_html(item["title"]),
            summary: strip_html(item["description"]),
            source_name: "naver",
            source_url: item["link"],
            external_id: ext_id,
            published_at: parse_date(item["pubDate"])
          )
          count += 1
        end
      rescue StandardError => e
        errors << "네이버(#{keyword}): #{e.message}"
      end
    end
    count
  end

  def self.fetch_rss(parish, source_name, rss_url, errors)
    count = 0
    begin
      uri = URI(rss_url)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 10) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end

      return 0 unless response.is_a?(Net::HTTPSuccess)

      doc = REXML::Document.new(response.body)
      doc.elements.each("rss/channel/item") do |item|
        title = item.elements["title"]&.text
        link = item.elements["link"]&.text
        desc = item.elements["description"]&.text
        pub_date = item.elements["pubDate"]&.text

        next unless title.present? && link.present?

        ext_id = Digest::MD5.hexdigest(link)
        next if NewsArticle.unscoped.exists?(external_id: ext_id)

        NewsArticle.create!(
          parish: parish,
          title: strip_html(title),
          summary: strip_html(desc.to_s).truncate(200),
          source_name: source_name,
          source_url: link,
          external_id: ext_id,
          published_at: parse_date(pub_date)
        )
        count += 1
      end
    rescue StandardError => e
      errors << "#{source_name}: #{e.message}"
    end
    count
  end

  def self.strip_html(text)
    return "" if text.blank?
    text.gsub(/<[^>]*>/, "").gsub(/&[a-z]+;/i, " ").strip
  end

  def self.parse_date(date_str)
    return Time.current if date_str.blank?
    Time.parse(date_str)
  rescue
    Time.current
  end
end
