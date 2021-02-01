module Iev::Termbase
  module Cli
    class Command < Thor
      include CommandHelper

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
      option :output, aliases: :o, default: Dir.pwd, desc: "Output directory"
      def db2yaml(dbfile)
        db = Sequel.sqlite(dbfile)
        collection = ConceptCollection.build_from_dataset(db[:concepts])
        save_collection_to_files(collection, options[:output])
      end
    end
  end
end
