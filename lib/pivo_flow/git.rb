module PivoFlow
  module Git
    extend self

    GIT_DIR = '.git'

    def current_branch_name
      Grit::Repo.new(Dir.pwd).head.name
    end

    def git_switch_branch(name)
      sys("git checkout #{name} 2>/dev/null || git checkout -b #{name}")
    end

    def git_commit title
      sys("git commit -m \"#{title}\" && git push")
    end

    def hub_pull_request message
      # if system("command -v hub")
      sys("hub pull-request -m \"#{message}\" -b #{previous_branch} -h")
    end

    def previous_branch
      `git describe --all $(git rev-parse @{-1})`.split("/")[-1].strip
    end

    # Check if git hook is already installed
    def git_hook_needed?
      !File.executable?(@git_hook_path) || !File.read(@git_hook_path).match(/#{@pf_git_hook_name} \$1/) || !pf_git_hook_valid?
    end

    def pf_git_hook_valid?
      File.executable?(@pf_git_hook_path) && FileUtils.compare_file(@pf_git_hook_path, @pf_git_hook_local_path)
    end

    def git_directory_present?
      File.directory?(File.join(@current_dir, GIT_DIR))
    end

    # Install git hook
    # Copy hook to <tt>.git/hooks</tt> directory and add a reference to this
    # executable file within <tt>prepare-commit-msg</tt> hook (it may be
    # helpful if user has his custom hooks)
    def install_git_hook
      puts "Installing prepare-commit-msg hook..."
      FileUtils.mkdir_p(File.dirname(@pf_git_hook_path))
      FileUtils.cp(@pf_git_hook_local_path, @pf_git_hook_path, preserve: true)
      puts "File copied..."
      unless File.exists?(@git_hook_path) && File.read(@git_hook_path).match(@pf_git_hook_name)
        File.open(@git_hook_path, "a") { |f| f.puts(@pf_git_hook_cmd) }
        puts "Reference to pf-prepare-commit-msg added to prepare-commit-msg..."
      end
      unless File.executable?(@git_hook_path)
        FileUtils.chmod 0755, @git_hook_path unless
        puts "Chmod on #{@git_hook_path} set to 755"
      end

      puts "Success!\n"
    end

    private

    def sys command
      @options["logger"].debug(command)
      system(command)
    end
  end
end
