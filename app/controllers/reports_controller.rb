#
# This file is part of meego-test-reports
#
# Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
#
# Authors: Sami Hangaslammi <sami.hangaslammi@leonidasoy.fi>
#          Jarno Keskikangas <jarno.keskikangas@leonidasoy.fi>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#

require 'digest/sha1'
require 'open-uri'
require 'file_storage'
require 'report_comparison'
require 'cache_helper'
require 'iconv'
require 'net/http'
require 'net/https'
require 'report_exporter'

class ReportsController < ApplicationController
  include CacheHelper
  layout        'report'

  before_filter :authenticate_user!,         :except => [:index, :show, :print, :compare]
  before_filter :validate_path_params,       :only   => [:show, :print]

  cache_sweeper :meego_test_session_sweeper, :only   => [:update, :delete, :publish]

  def index
    @profiles = TargetLabel.targets
    @products = Product.by_profile_by_testset(release)
    @show_rss = true
    render :layout => "application"
  end

  def preview
    @test_session     = MeegoTestSession.fetch_fully(params[:id])
    @report           = @test_session
    @release_versions = VersionLabel.all.map { |release| release.label }
    @targets          = TargetLabel.targets
    @testsets         = MeegoTestSession.release(@selected_release_version).testsets
    @product          = MeegoTestSession.release(@selected_release_version).popular_products
    @build_id         = MeegoTestSession.release(@selected_release_version).popular_build_ids
    @build_diff       = []
    @editing          = true
    @wizard           = true
    @no_upload_link   = true
  end

  def publish
    report = MeegoTestSession.find(params[:id])
    report.update_attribute(:published, true)

    flash[:notice] = "Your report has been successfully published"
    redirect_to show_report_path(report.release.label, report.target, report.testset, report.product, report)
  end

  def show
    @test_session = MeegoTestSession.fetch_fully(params[:id])
    @nft_trends   = NftHistory.new(@test_session) if @test_session.has_nft?
    @report       = @test_session
    @attachments  = @test_session.attachments
    @history      = history(@test_session, 5)
    @build_diff   = build_diff(@test_session, 4)
    @target       = @test_session.target
    @testset      = @test_session.testset
    @product      = @test_session.product
  end

  def print
    @test_session = MeegoTestSession.fetch_fully(params[:id])
    @report       = @test_session
    @attachments  = @test_session.attachments
    @nft_trends   = NftHistory.new(@test_session) if @test_session.has_nft?
    @build_diff   = []
    @email        = true
  end

  def edit
    @test_session     = MeegoTestSession.fetch_fully(params[:id])
    @report           = @test_session
    @attachments      = @test_session.attachments
    @build_diff       = []
    @release_versions = VersionLabel.all.map { |release| release.label }
    @targets          = TargetLabel.targets
    @testsets         = MeegoTestSession.release(@selected_release_version).testsets
    @product          = MeegoTestSession.release(@selected_release_version).popular_products
    @build_id         = MeegoTestSession.release(@selected_release_version).popular_build_ids
    @editing          = true
    @no_upload_link   = true
  end

  def update
    @report = MeegoTestSession.find(params[:id])
    @report.update_attributes(params[:report]) # Doesn't check for failure
    @report.update_attribute(:editor, current_user)

    #TODO: Fix templates so that normal 'head :ok' response is enough
    render :text => @report.tested_at.strftime('%d %B %Y')
  end

  #TODO: This should be in comparison controller
  def compare
    @comparison = ReportComparison.new()
    @release_version = params[:release_version]
    @target = params[:target]
    @testset = params[:testset]
    @comparison_testset = params[:comparetype]
    @compare_cache_key = "compare_page_#{@release_version}_#{@target}_#{@testset}_#{@comparison_testset}"

    MeegoTestSession.published_hwversion_by_release_version_target_testset(@release_version, @target, @testset).each{|product|
        left = MeegoTestSession.by_release_version_target_testset_product(@release_version, @target, @testset, product.product).first
        right = MeegoTestSession.by_release_version_target_testset_product(@release_version, @target, @comparison_testset, product.product).first
        @comparison.add_pair(product.product, left, right)
    }
    @groups = @comparison.groups
    render :layout => "report"
  end

  def destroy
    report = MeegoTestSession.find(params[:id])
    report.destroy
    redirect_to root_path
  end

  private

  def validate_path_params
    query_params = {}
    query_params[:version_label_id] = VersionLabel.find_by_label(params[:release_version]) if params[:release_version]

    [:target, :testset, :product, :id].each { |key| query_params[key] = params[key] if params[key]}
    raise ActiveRecord::RecordNotFound unless MeegoTestSession.where(query_params).count == 1
  end

  protected

  def history(s, cnt)
    MeegoTestSession.where("(tested_at < '#{s.tested_at}' OR tested_at = '#{s.tested_at}' AND created_at < '#{s.created_at}') AND target = '#{s.target.downcase}' AND testset = '#{s.testset.downcase}' AND product = '#{s.product.downcase}' AND published = 1 AND version_label_id = #{s.version_label_id}").
        order("tested_at DESC, created_at DESC").limit(cnt).
        includes([{:features => :meego_test_cases}, {:meego_test_cases => :feature}])
  end

  def build_diff(s, cnt)
    sessions = MeegoTestSession.published.profile(s.target).testset(s.testset).product_is(s.product).
        where("version_label_id = #{s.version_label_id} AND build_id < '#{s.build_id}' AND build_id != ''").
        order("build_id DESC, tested_at DESC, created_at DESC")

    latest = []
    sessions.each do |session|
      latest << session if (latest.empty? or session.build_id != latest.last.build_id)
    end

    diff = MeegoTestSession.where(:id => latest).
        order("build_id DESC, tested_at DESC, created_at DESC").limit(cnt).
        includes([{:features => :meego_test_cases}, {:meego_test_cases => :feature}])
  end

  def just_published?
    @published
  end

end
