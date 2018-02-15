# -*- encoding : utf-8 -*-
module PivoFlow
  class Story
    def initialize project, story
      @project = project
      @story = story
    end

    ## CLI
    def show_info
      puts to_s(true)

      if story.tasks.any?
        puts "\n[TASKS]"
        print_tasks(story.tasks)
      end

      if story.comments.any?
        puts "\n[COMMENTS]"
        print_comments(story.comments)
      end
    end

    def print_tasks tasks
      tasks.each { |task| puts task_string(task) }
    end

    def print_comments comments
      comments.each { |c| puts comment_string(c) }
    end

    ## Helpers
    def update state
      if story.story_type == "chore" && state == :finished
        state = :accepted
      end
      story.owner_ids |= [me.id]
      story.current_state = state

      if story.save
        puts "Story updated in Pivotal Tracker"
        true
      else
        error_message = "ERROR"
        error_message += ": #{story.errors.first}"
        puts error_message
      end
    end

    def branch_name
      "#{story_type}/pt-##{id}"
    end

    def owner_ids
      story.owner_ids
    end

    def current_state
      story.current_state
    end

    def to_s long = false
      vars = {
        story_id: story.id,
        requested_by: story.requested_by,
        name: truncate(story.name),
        full_name: story.name,
        story_type_sign: type_icon,
        story_type: story.story_type,
        estimate: estimate_points,
        owner: story_owner,
        description: story.description,
        labels: story_labels.colorize(:green),
        state_sign: story_state_sign,
        state: story.current_state,
        url: story.url.colorize(:blue),
      }

      if long
        <<~EOS % vars
          [#%{story_id}] %{full_name}
          URL:          %{url}
          State:        %{state}
          Labels:       %{labels}
          Type:         %{story_type} (%{estimate})
          Requester:    %{requested_by}
          Owner:        %{owner}
          Description:
            %{description}
        EOS
      else
        "%{story_type_sign} [#%{story_id}] (%{state_sign}) [%{estimate} pts.] %{owner} %{name} %{labels}".colorize(story_color) % vars
      end
    end

    private
    attr_reader :story, :project

    def comments
      @comments ||= story.comments.select { |n| n.text !~ /Commit by/ }
    end

    def story_color
      # if users_story?(story)
      #   case story.story_type
      #     when "feature" then :green
      #     when "bug" then :red
      #     when "chore" then :yellow
      #     else :white
      #   end
      # else
        case story.story_type
          when "feature" then :light_green
          when "bug" then :light_red
          when "chore" then :ligh_yellow
          else :light_white
        end
      # end
    end

    def comment_string comment
      person = project.people[comment.person_id]
      if person.present?
        "\t[#{comment.created_at.to_time}] (#{person.name}) #{comment.text}"
      else
        "\t[#{comment.created_at.to_time}] #{comment.text}"
      end
    end

    def task_string task
      complete = task.complete ? "x" : " "
      "\t[#{complete}] #{task.description}"
    end

    def type_icon
      case story.story_type
      when "feature"
        "⭐ "
      when "bug"
        "🐞 "
      when "chore"
        "⚙️ "
      end
    end

    def truncate string
      string.length > 80 ? "#{string[0..80]}..." : string
    end

    def story_owner
      if owners.any?
        "(#{owners.map{ |o| o[:initials] }.join(", ")})"
      else
        "(--)"
      end
    end

    def owners
      @owners ||= story.owner_ids.map do |id|
        project.people[id.to_i]
      end
    end

    def story_labels
      story.labels.map{ |l| "##{l.name}" }.join(", ")
    end

    def story_state_sign
      case story.current_state
      when "accepted"
        "👍 "
      when "rejected"
        "👎 "
      when "delivered"
        "🚀 "
      when "finished"
        "🏁 "
      when "started"
        "⏳ "
      when "planned"
        "📅 "
      when "unstarted"
        "📅 "
      when "unscheduled"
        "📅 "
      end
    end

    def estimate_points
      unless story.estimate.nil?
        story.estimate < 0 ? "?" : story.estimate.to_i
      else
        "-"
      end
    end
  end
end
