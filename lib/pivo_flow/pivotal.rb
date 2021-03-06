# -*- encoding : utf-8 -*-
module PivoFlow
  class Pivotal < Base
    include PivoFlow::State
    include PivoFlow::Git

    def run
      @client = TrackerApi::Client.new(
        token: @options["api-token"],
        logger: logger,
        auto_paginate: false,
      )
    end

    def logger
      # @options["logger"] ||= Logger.new(STDOUT).tap{ |l| l.level = Logger::ERROR }
      @options["logger"] ||= Logger.new(STDOUT).tap{ |l| l.level = Logger::INFO }
    end

    def project
      @options[:project] ||= PivoFlow::Project.new(
        @client.project(@options["project-id"])
      )
    rescue Exception => e
      message = "Pivotal Tracker: #{e.message}\n" +
      "[TIPS] It means that your configuration is wrong. You can reset your settings by running:\n\tpf reconfig"
      raise PivoFlow::Errors::UnsuccessfulPivotalConnection, message
    end

    def me
      @me ||= @client.me
    end

    def project_stories
      project.fetch_stories
    end

    def current_story
      find_story(current_story_id)
    end

    def list_stories_to_output stories, activity="start"
      if (stories.nil? || stories.empty?)
        puts "No stories to show"
        return 1
      end

      HighLine.new.choose do |menu|
        menu.header = "\n--- STORIES FROM PIVOTAL TRACKER ---\nChoose a story to #{activity}"
        menu.prompt = "story no. "
        menu.select_by = :index
        stories.each do |story|
          # menu.choice(story_string(story).fix_encoding) do |answer|
          menu.choice(story.to_s) do |answer|
            show_story(answer.match(/\[#(?<id>\d+)\]/)[:id])
          end
        end
        menu.choice("Show more") { show_stories(stories.count + 10) }
      end
    end

    def deliver
      list_stories_to_output(project.finished_stories, "deliver")
    end

    def show_story story_id
      story = find_story(story_id)
      story.show_info
      ask_for = story.current_state == "finished" ? "deliver" : "start"
      proceed = ask_question "Do you want to #{ask_for} this story? (y/n)"
      accepted_answers = %w[yes y sure ofc jup yep yup ja tak]
      if accepted_answers.include?(proceed.downcase)
        story.current_state == "finished" ? deliver_story(story_id) : pick_up_story(story_id)
      else
        show_stories
      end
    end

    def find_story story_id
      project.story(story_id)
    end

    def pick_up_story story_id
      if start_story(story_id)
        save_story_id_to_file(story_id)
      end
    end

    def start_story story_id
      story = find_story(story_id)
      story.update(:started)
      create_branch(story_id)
    end

    def create_branch story_id = nil
      story = find_story(story_id || current_story_id)

      if story.nil?
        puts "Sorry, this story could not be found (#{story_id})"
        return
      end

      git_switch_branch(story.branch_name)
      save_story_id_to_file(story_id)
    end

    def finish_story story_id
      if story_id.present?
        story = find_story(story_id)
        story.update(:finished)
      end
      remove_story_id_file
    end

    def deliver_story story_id
      story = find_story(story_id)
      story.update(:delivered)
    end

    def show_stories count = 9
      stories = project.available_stories(count)
      stories.sort_by!{ |s| users_story?(s) ? -1 : 1 }
      list_stories_to_output(stories)
    end

    def commit title
      if title.nil? || title.to_s.empty?
        title = current_story.name
        e d
      commit_message = "[##{current_story_id}] #{title}"
      git_commit(commit_message)
    end

    def pull_request title
      if title.nil? || title.to_s.empty?
        title = current_story.name
      end
      title = "[##{current_story_id}] #{title}"
      hub_pull_request(title)
    end
  end
end
