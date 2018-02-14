module PivoFlow
  module State
    extend self

    def current_branch_name
      Grit::Repo.new(Dir.pwd).head.name
    end

    def story_id_tmp_path
      File.join(Dir.pwd, "tmp", ".pivo_flow")
    end

    def current_story_id_file_path
      File.join(story_id_tmp_path, "current_story_id")
    end

    def remove_story_id_file
      FileUtils.remove_file(current_story_id_file_path)
    end

    def save_story_id_to_file story_id
      FileUtils.mkdir_p(story_id_tmp_path)
      File.open(current_story_id_file_path, 'w') { |f| f.write(story_id) }
    end

    def current_story_id
      match_data = current_branch_name.match(/pt-#?([0-9]*)/)

      if match_data.present?
        match_data[1]
      elsif File.exist?(current_story_id_file_path)
        File.read(current_story_id_file_path)
      end
    end
  end
end
