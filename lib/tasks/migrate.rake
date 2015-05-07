namespace :migrate do
  desc "GitLab CI | Clean running builds"
  task fetch_tags: :environment do
    Project.all.each do |project|
      builds = Build.where(project_id: project.id)
      builds.each do |build|
        puts "fetching tag for commit #{sha} (build ##{build.id}"
      end
    end
  end
end
