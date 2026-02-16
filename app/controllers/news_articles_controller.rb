class NewsArticlesController < ApplicationController
  def index
    authorize NewsArticle
    @source = params[:source]
    @news_articles = policy_scope(NewsArticle).recent
    @news_articles = @news_articles.by_source(@source) if @source.present?
    @news_articles = @news_articles.page(params[:page]).per(12)
  end

  def show
    @news_article = NewsArticle.find(params[:id])
    authorize @news_article
  end

  def refresh
    authorize NewsArticle, :refresh?
    NewsFetchJob.perform_later
    redirect_to news_articles_path, notice: "뉴스를 새로고침하고 있습니다. 잠시 후 확인해주세요."
  end
end
