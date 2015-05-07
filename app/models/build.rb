# == Schema Information
#
# Table name: builds
#
#  id          :integer          not null, primary key
#  project_id  :integer
#  ref         :string(255)
#  status      :string(255)
#  finished_at :datetime
#  trace       :text
#  created_at  :datetime
#  updated_at  :datetime
#  sha         :string(255)
#  started_at  :datetime
#  tmp_file    :string(255)
#  before_sha  :string(255)
#  push_data   :text
#  runner_id   :integer
#

class Build < ActiveRecord::Base
  belongs_to :project
  belongs_to :runner

  serialize :push_data

  attr_accessible :project_id, :ref, :sha, :before_sha,
    :status, :finished_at, :trace, :started_at, :push_data, :runner_id, :project_name, :id

  validates :before_sha, presence: true
  validates :sha, presence: true
  validates :ref, presence: true
  validates :status, presence: true
  validate :valid_commit_sha

  scope :running, ->() { where(status: "running") }
  scope :pending, ->() { where(status: "pending") }
  scope :success, ->() { where(status: "success") }
  scope :failed, ->() { where(status: "failed")  }
  scope :uniq_sha, ->() { select('DISTINCT(sha)') }

  def self.last_month
    where('created_at > ?', Date.today - 1.month)
  end

  def self.first_pending
    pending.where(runner_id: nil).order('created_at ASC').first
  end

  def self.first_pending_for_ref(ref)
    pending.where(runner_id: nil, ref: ref).order('created_at ASC').first
  end

  def self.create_from(build)
    new_build = build.dup
    new_build.status = :pending
    new_build.runner_id = nil
    new_build.save
  end

  state_machine :status, initial: :pending do
    event :run do
      transition pending: :running
    end

    event :drop do
      transition running: :failed
    end

    event :success do
      transition running: :success
    end

    event :cancel do
      transition [:pending, :running] => :canceled
    end

    after_transition :pending => :running do |build, transition|
      build.update_attributes started_at: Time.now
    end

    after_transition any => [:success, :failed, :canceled] do |build, transition|
      build.update_attributes finished_at: Time.now
      project = build.project

      if project.web_hooks?
        WebHookService.new.build_end(build)
      end

      if project.email_notification?
        if build.status.to_sym == :failed || !project.email_only_broken_builds
          NotificationService.new.build_ended(build)
        end
      end
    end

    state :pending, value: 'pending'
    state :running, value: 'running'
    state :failed, value: 'failed'
    state :success, value: 'success'
    state :canceled, value: 'canceled'
  end

  def valid_commit_sha
    if self.sha =~ /\A00000000/
      self.errors.add(:sha, " cant be 00000000 (branch removal)")
    end
  end

  def compare?
    gitlab? && before_sha
  end

  def gitlab?
    project.gitlab?
  end

  def ci_skip?
    !!(git_commit_message =~ /(\[ci skip\])/)
  end

  def git_author_name
    commit_data[:author][:name] if commit_data && commit_data[:author]
  end

  def git_author_email
    commit_data[:author][:email] if commit_data && commit_data[:author]
  end

  def git_commit_message
    commit_data[:message] if commit_data
  end

  def short_before_sha
    before_sha[0..8]
  end

  def short_sha
    sha[0..8]
  end

  def tags
    return @tags if !!@tags
    @tags = []
    begin
      @tags = MultiJson.load(`curl --header "PRIVATE-TOKEN: #{GitlabCi.config.gitlab.private_token}" "http://col-git01.columba.intern/api/v3/projects/#{project_id}/repository/tags"`)
      @tags.select!{|t|t['commit']['id']=='e6d504bdee3e43c245abb683541a0cbf5f93d821'}
    rescue Exception => e
      Rails.logger.warn(e.message)
    end
    @tags
  end

  def trace_html
    html = Ansi2html::convert(trace) if trace.present?
    html ||= ''
  end

  def report_log
    text = HTTParty.get("#{ENV['REPORTS_URL']}project-#{project_id}/#{ref}/#{sha}/rspec/#{id}/test.log").body
    text
  end

  def report_html(fails_only=false)
    report_url = "#{ENV['REPORTS_URL']}project-#{project_id}/#{ref}/#{sha}/rspec/#{id}"
    Rails.logger.info "fetching reports from #{report_url}..."
    html_src = HTTParty.get(report_url)
    html_src.gsub!("file:///home/gitlab_ci_runner/gitlab-ci-runner/tmp/reports/", ENV['REPORTS_URL']) if ENV['REPORTS_URL'] && !!html_src
    parsed_html = Nokogiri::HTML(html_src)
    parsed_html.xpath("//script").remove
    if fails_only
      parsed_html.css('body > .rspec-report .results .example.failed').to_html
    else
      parsed_html.css('body > .rspec-report .results > .example_group').to_html
    end
  end

  def report_json
    if complete?
      return @report_json if !!@report_json
      report_url = "#{ENV['REPORTS_URL']}project-#{project_id}/#{ref}/#{sha}/rspec/#{id}/data.json"
      json_response = HTTParty.get(report_url)
      if json_response.code.to_s == '200'
        begin
          @report_json = MultiJson.load(json_response.body)
          @report_json
        rescue Exception => e
          Rails.logger.warn e.message
          {}
        end
      else
        {}
      end
    else
      {}
    end
  end

  def started?
    !pending? && !canceled? && started_at
  end

  def active?
    running? || pending?
  end

  def complete?
    canceled? || success? || failed?
  end

  def commands
    project.scripts
  end

  def commit_data
    push_data[:commits].each do |commit|
      return commit if commit[:id] == sha
    end
  rescue
    nil
  end

  # Build a clone-able repo url
  # using http and basic auth
  def repo_url
    auth = "gitlab-ci-token:#{project.token}@"
    url = project.gitlab_url + ".git"
    url.sub(/^https?:\/\//) do |prefix|
      prefix + auth
    end
  end

  def timeout
    project.timeout
  end

  def allow_git_fetch
    project.allow_git_fetch
  end

  def project_name
    project.name
  end

  def project_recipients
    recipients = project.email_recipients.split(' ')
    recipients << git_author_email if project.email_add_committer?
    recipients.uniq
  end

  def duration
    if started_at && finished_at
      finished_at - started_at
    elsif started_at
      Time.now - started_at
    end
  end
end
