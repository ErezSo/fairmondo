#
#
# == License:
# Fairmondo - Fairmondo is an open-source online marketplace.
# Copyright (C) 2013 Fairmondo eG
#
# This file is part of Fairmondo.
#
# Fairmondo is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairmondo is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairmondo.  If not, see <http://www.gnu.org/licenses/>.
#
class ArticleTemplatesController < ApplicationController
  respond_to :html
  responders :location, :flash

  before_action -> { render_css_from_controller('articles') }, except: [:destroy]
  before_action :set_article_template, only: [:edit, :update, :destroy]

  def new
    @article_template = current_user.articles.build
    authorize @article_template
  end

  def edit
    authorize @article_template
  end

  def update
    authorize @article_template

    save_images unless @article_template.update(params.for(@article_template).refine)
    respond_with(@article_template, location: -> { collection_url })
  end

  def create
    @article_template = current_user.articles.build(params.for(Article).refine)
    authorize @article_template
    @article_template.state = :template

    save_images unless @article_template.save
    respond_with(@article_template, location: -> { collection_url })
  end

  def destroy
    authorize @article_template
    @article_template.destroy
    respond_with(@article_template, location: -> { collection_url })
  end

  private

  def set_article_template
    @article_template = Article.unscoped.find(params[:id])
  end

  def collection_url
    user_path(current_user, type: 'templates')
  end

  def save_images
    # At least try to save the images -> not persisted in browser
    @article_template.images.each do |image|
      image.save
    end
  end
end
