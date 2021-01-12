module Iev::Termbase
  module Cli
    class Command < Thor
      desc "xlsx2yaml FILE", "Parsing Excel exports to IEV yaml."
      option :output, aliases: :o, default: Dir.pwd, desc: "Output directory"

      option(
        :write,
        default: true,
        type: :boolean,
        desc: "Write or Stream to the output buffer",
      )

      def xlsx2yaml(file)
        db = Sequel.sqlite
        DbWriter.new(db).import_spreadsheet(file)
        collection = ConceptCollection.build_from_dataset(db[:concepts])

        if collection && options[:write]
          write_to_file(file, collection, options)
        else
          UI.say(collection.to_yaml)
        end
      end

      private

      def write_to_file(file, collection, options)
        output_dir = Pathname.new(options[:output].to_s)
        collection.to_file(collection_file_path(file, output_dir))

        concept_dir = output_dir.join("concepts")
        FileUtils.mkdir_p(concept_dir)unless concept_dir.exist?

        collection.each do |key, concept|
          concept.to_file(concept_dir.join("concept-#{key}.yaml"))
        end
      end

      def collection_file_path(file, output_dir)
        output_dir.join(Pathname.new(file).basename.sub_ext(".yaml"))
      end
    end
  end
end
