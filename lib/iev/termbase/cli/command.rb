module Iev::Termbase
  module Cli
    class Command < Thor
      desc "xlsx2yaml FILE", "Parsing Excel exports to IEV yaml."
      option :output, aliases: :o, default: Dir.pwd, desc: "Output directory"

      def xlsx2yaml(file)
        db = Sequel.sqlite
        DbWriter.new(db).import_spreadsheet(file)
        collection = ConceptCollection.build_from_dataset(db[:concepts])
        save_collection_to_files(collection, options[:output])
      end

      desc "xlsx2db FILE, DB_FILE", "Imports Excel to SQLite database."
      def xlsx2db(file, dbfile)
        # Instantiating an in-memory db and dumping it later is faster than
        # just working on file db.
        db = Sequel.sqlite
        DbWriter.new(db).import_spreadsheet(file)
        save_db_to_file(db, dbfile)
      end

      desc "db2yaml DB_FILE", "Exports SQLite to IEV YAMLs."
      def db2yaml(dbfile)
        db = Sequel.sqlite(dbfile)
        collection = ConceptCollection.build_from_dataset(db[:concepts])
        save_collection_to_files(collection, options[:output])
      end

      private

      def save_collection_to_files(collection, output_dir)
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
        puts "Saving database to file..."
        src_db.synchronize do |src_conn|
          dest_conn = SQLite3::Database.new(dbfile)
          b = SQLite3::Backup.new(dest_conn, "main", src_conn, "main")
          b.step(-1)
          b.finish
        end
      end

      def collection_file_path(file, output_dir)
        output_dir.join(Pathname.new(file).basename.sub_ext(".yaml"))
      end
    end
  end
end
