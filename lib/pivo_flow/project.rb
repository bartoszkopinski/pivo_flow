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

    def fetch_stories(count = 100, filter = nil)
      conditions = { limit: count }

      if filter
        conditions[:filter] = filter
      end

      project.stories(conditions).map do |s|
        stories[s.id] = PivoFlow::Story.new(self, s)
      end
    end

    def story id
      stories[id] ||= PivoFlow::Story.new(self, project.story(id))
    end

    def stories
      @stories ||= {}
    end

    private
    attr_reader :project
  end
end
