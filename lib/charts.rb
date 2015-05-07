module Charts
  class Chart
    attr_reader :labels, :total, :success, :project, :build_times

    def initialize(project)
      @labels = []
      @total = []
      @success = []
      @build_times = []
      @project = project

      collect
    end


    def push(from, to, format)
      @labels << from.strftime(format)
      @total << project.builds.where("? > created_at AND created_at > ?", to, from).count
      @success << project.builds.where("? > created_at AND created_at > ?", to, from).success.count
    end
  end

  class YearChart < Chart
    def collect
      13.times do |i|
        start_month = (Date.today.years_ago(1) + i.month).beginning_of_month
        end_month = start_month.end_of_month

        push(start_month, end_month, "%d %B %Y")
      end
    end
  end

  class MonthChart < Chart
    def collect
      30.times do |i|
        start_day = Date.today - 30.days + i.days
        end_day = Date.today - 30.days + i.day + 1.day

        push(start_day, end_day, "%d %B")
      end
    end
  end

  class WeekChart < Chart
    def collect
      7.times do |i|
        start_day = Date.today - 7.days + i.days
        end_day = Date.today - 7.days + i.day + 1.day

        push(start_day, end_day, "%d %B")
      end
    end
  end

  class BuildTime < Chart
    def collect
      builds = project.builds.where('builds.finished_at is NOT NULL AND builds.started_at is NOT NULL AND builds.status = "success" AND TIMESTAMPDIFF(MINUTE, `builds`.`started_at`, `builds`.`finished_at`) > 30').group(:sha).last(Settings.charts['builds_time_span'])
      project_tags = project.tags
      builds.select! do |build|
        build_tags = project_tags.select!{|t| t['commit']['id'] == build.sha }
        !!build_tags && build_tags.is_a?(Array) && build_tags.size > 0
      end
      builds.each do |build|
        @labels << build.short_sha
        @build_times << (build.duration / 60)
      end
    end
  end
end
