module PivoFlow
  class Cli
    include PivoFlow::State

    def initialize *args
      @args = args
    end

    def go!
      Signal.trap(2) {
        puts "\nkkthxbye!"
        return 0
      }
      begin
        return parse_argv(@args)
      rescue *PivoFlow::Errors.exceptions => e
        puts "[ERROR] #{e}"
        return 1
      end
    end

    private

    # available commands

    def stories
      pivotal_object.show_stories
    end

    def set story_id = nil
      unless story_id
        puts "Ok, but which story?"
        return 1
      end

      story_id = story_id.to_s.delete("#")
      pivotal_object.save_story_id_to_file(story_id)
      puts "Story ##{story_id} set as current"
    end

    def start story_id = nil
      story_id ||= current_story_id

      unless story_id
        h = HighLine.new
        story_id = h.ask("Story ID:\t") do |q|
          q.responses[:ask_on_error] = :question
          q.responses[:not_valid] = "It can't be empty, sorry"
          q.validate = ->(id) { !id.empty? }
        end
      end

      story_id = story_id.to_s.delete("#")
      pivotal_object.pick_up_story(story_id)
    end

    def finish story_id = nil
      story_id ||= current_story_id

      unless story_id
        puts no_story_found_message
        return 1
      end

      story_id = story_id.to_s.delete("#")
      pivotal_object.finish_story(story_id)
    end

    def deliver
      pivotal_object.deliver
    end

    def clear
      unless current_story_id.nil?
        FileUtils.remove_file(current_story_id_file_path)
        puts "Current pivotal story id cleared."
      else
        puts no_story_found_message
        return 1
      end
    end

    def branch
      unless current_story_id
        puts no_story_found_message
        return 1
      end

      pivotal_object.create_branch(current_story_id)
    end

    def current
      puts current_story_id || no_story_found_message
    end

    def reconfig
      PivoFlow::Base.new.reconfig
    end

    def info
      pivotal_object.show_info
    end

    def version
      puts PivoFlow::VERSION
    end

    # additional methods

    def pivotal_object
      @pivotal_object ||= PivoFlow::Pivotal.new(@options)
    end

    def no_story_found_message
      "Story not started!"
    end

    def no_method_error
      puts "You forgot a method name"
    end

    def invalid_method_error
      puts "Ups, no such method..."
    end

    def parse_argv(args)
      @options = {}

      opt_parser = OptionParser.new do |opts|
        opts.banner =   "\nPivoFlow ver. #{PivoFlow::VERSION}\nUsage: pf <COMMAND> [OPTIONS]\n"
        opts.separator  "Commands"
        opts.separator  "     branch            create git branch locally based on current set ticket using 'info' command"
        opts.separator  "     clear             clear STORY_ID from temp file"
        opts.separator  "     current           show STORY_ID from temp file"
        opts.separator  "     deliver           show finished stories and mark selected as delivered in Pivotal Tracker"
        opts.separator  "     help              show this message"
        opts.separator  "     finish [STORY_ID] finish story on Pivotal"
        opts.separator  "     info              show info about current story"
        opts.separator  "     reconfig          clear API_TOKEN and PROJECT_ID from git config and setup new values"
        opts.separator  "     start <STORY_ID>  start a story of given ID (update in Pivotal)"
        opts.separator  "     set <STORY_ID>    set a story of given ID locally (do not update Pivotal)"
        opts.separator  "     stories           list stories for current project"
        opts.separator  "     version           show gem version"
        opts.separator  ""
        opts.separator  "Options"

        opts.on_tail("-h", "--help", "Show this message") do
          puts opts
          return 1
        end

        opts.on_tail("-v", "--version", "Show version") do
          puts PivoFlow::VERSION
          return 1
        end

        opts.on("-t <API_TOKEN>", "--token <API_TOKEN>", "Set Pivotal Tracker API TOKEN") do |api_token|
          @options["api-token"] = api_token
        end

        opts.on("-p <PROJECT_ID>", "--project <PROJECT_ID>", Numeric, "Set Pivotal Tracker PROJECT_ID") do |project_id|
          @options["project-id"] = project_id
        end

      end

      opt_parser.parse!(args)

      case args[0]
      when "start", "finish", "set"
        self.send(args[0].to_sym, args[1])
      when "help"
        puts opt_parser
      when "clear", "current", "deliver", "info", "reconfig", "stories", "branch"
        self.send(args[0].to_sym)
      when nil
        stories
      else
        invalid_method_error
        return 1
      end
      return 0
    end
  end
end
