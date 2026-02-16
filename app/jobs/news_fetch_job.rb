class NewsFetchJob < ApplicationJob
  queue_as :default

  def perform
    Parish.find_each do |parish|
      results = NewsFetcherService.fetch_all(parish)
      total = results[:naver] + results[:catholic_news] + results[:diocese]

      Rails.logger.info "[NewsFetchJob] Parish #{parish.name}: #{total}건 수집 (네이버:#{results[:naver]}, 가톨릭뉴스:#{results[:catholic_news]}, 교구:#{results[:diocese]})"

      if results[:errors].any?
        Rails.logger.warn "[NewsFetchJob] Errors: #{results[:errors].join(', ')}"
      end
    end
  end
end
