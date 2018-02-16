# -*- encoding : utf-8 -*-
module PivoFlow
  class Project
    def initialize project
      @project = project
    end

    def people
      @people ||= project.memberships.map(&:person).each_with_object({}) do |p, h|
        h[p.id] = p
      end
    end

    def finished_stories
      project.fetch_stories(10, "owner:#{me.initials} state:finished")
    end

    def available_stories count
      project.fetch_stories(
          count,
          "label:backend (state:started OR state:rejected OR state:planned OR state:unstarted OR state:unscheduled)"
        )
        .sort_by{ |s| s.own? ? -1 : 1 }
    end

    def story id
      stories[id] ||= PivoFlow::Story.new(self, project.story(id))
    end

    def stories
      @stories ||= {}
    end

    def me
      @me ||= project.client.me
    end

    def fetch_stories(count = 100, filter = nil)
      conditions = { limit: count }

      if filter
        conditions[:filter] = filter
      end

      project.stories(conditions).map do |s|
        stories[s.id] = PivoFlow::Story.new(self, s)
      end
    end

    private
    attr_reader :project
  end
end
