module Iev::Termbase
  module Cli
    class Command < Thor
      include CommandHelper

      desc "xlsx2yaml FILE", "Converts Excel IEV exports to YAMLs."
      def xlsx2yaml(file)
        handle_generic_options(options)
        db = Sequel.sqlite
        DbWriter.new(db).import_spreadsheet(file)
        collection = ConceptCollection.build_from_dataset(db[:concepts])
        save_collection_to_files(collection, options[:output])
      end

      desc "xlsx2db FILE", "Imports Excel to SQLite database."
      def xlsx2db(file)
        handle_generic_options(options)
        # Instantiating an in-memory db and dumping it later is faster than
        # just working on file db.
        db = Sequel.sqlite
        DbWriter.new(db).import_spreadsheet(file)
        save_db_to_file(db, options[:output])
      end

      desc "db2yaml DB_FILE", "Exports SQLite to IEV YAMLs."
      def db2yaml(dbfile)
        handle_generic_options(options)
        db = Sequel.sqlite(dbfile)
        collection = ConceptCollection.build_from_dataset(db[:concepts])
        save_collection_to_files(collection, options[:output])
      end

      # Options must be declared at the bottom because Thor must have commands
      # defined in advance.

      def self.shared_option(name, methods:, **kwargs)
        [*methods].each { |m| option name, for: m, **kwargs }
      end

      shared_option :output,
        desc: "Output directory",
        aliases: :o,
        default: Dir.pwd,
        methods: %i[xlsx2yaml db2yaml]

      shared_option :output,
        desc: "Output file",
        aliases: :o,
        default: File.join(Dir.pwd, "concepts.sqlite3"),
        methods: :xlsx2db
    end
  end
end
