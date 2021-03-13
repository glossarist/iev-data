# frozen_string_literal: true

# (c) Copyright 2020 Ribose Inc.
#

module IEV::Termbase
  module CLI
    module CommandHelper
      include CLI::UI

      protected

      def save_collection_to_files(collection, output_dir)
        info "Writing concepts to files..."
        output_dir = Pathname.new(output_dir.to_s)

        concept_dir = output_dir.join("concepts")
        FileUtils.mkdir_p(concept_dir)

        collection.each do |key, concept|
          concept.to_file(concept_dir.join("concept-#{key}.yaml"))
        end
      end

      # Note: Implementation examples here:
      # https://www.rubydoc.info/github/luislavena/sqlite3-ruby/SQLite3/Backup
      def save_db_to_file(src_db, dbfile)
        info "Saving database to a file..."
        src_db.synchronize do |src_conn|
          dest_conn = SQLite3::Database.new(dbfile)
          b = SQLite3::Backup.new(dest_conn, "main", src_conn, "main")
          b.step(-1)
          b.finish
        end
      end

      def summary
        info "Done!"
      end

      def collection_file_path(file, output_dir)
        output_dir.join(Pathname.new(file).basename.sub_ext(".yaml"))
      end

      # Handles various generic options, e.g. detailed debug switches.
      # Assigns some global variables accordingly, so these settings are
      # available throughout the program.
      def handle_generic_options(options)
        $TERMBASE_PROFILE = options[:profile]
        $TERMBASE_PROGRESS = options.fetch(:progress, !ENV["CI"])
        $TERMBASE_DEBUG_TERM_ATTRIBUTES = options[:debug_term_attributes]
      end

      def filter_dataset(db, options)
        query = db[:concepts]

        if options[:only_concepts]
          query = query.where(Sequel.ilike(:ievref, options[:only_concepts]))
        end

        if options[:only_languages]
          query = query.where(language: options[:only_languages].split(","))
        end

        query
      end
    end
  end
end
