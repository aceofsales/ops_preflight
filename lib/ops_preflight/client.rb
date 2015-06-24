module OpsPreflight
  class Client < Thor
    include Thor::Actions
    include ExitCode

    namespace :default

    source_root OpsPreflight.root_path

    class_option :verbose, :aliases => '-v', :type => :boolean
    class_option :simulate, :aliases => '-S', :type => :boolean
    class_option :trace, :aliases => '-t', :type => :boolean

    desc "init", "Initialize application to work with preflight"
    def init
      copy_file 'data/preflight.yml', 'config/preflight.yml'
      say 'Please edit config/preflight.yml to finish setting up preflight.'
    end

    desc "setup <rails_env>", "Set up the server's preflight environment"
    def setup(rails_env)
      run "bundle exec mina setup RAILS_ENV=#{rails_env} #{Config.new.client_args(rails_env)} #{mina_args}", :verbose => false
    end

    desc "deploy <rails_env>", "Deploys to the configured app"
    method_option :stack_name, :type => :string
    def deploy(rails_env)
      run "bundle exec mina deploy RAILS_ENV=#{rails_env} #{deploy_args(rails_env)} #{mina_args}", :verbose => false
    end

    # Fixes thor's banners when used with :default namespace
    def self.banner(command, namespace = nil, subcommand = false)
      "#{basename} #{command.formatted_usage(self, false, subcommand)}"
    end

    no_tasks do
      def deploy_args(rails_env)
        args = Config.new.client_args(rails_env)
        args << "OPSWORKS_STACK_NAME=#{options[:stack_name]}" if options[:stack_name]
        args
      end

      def mina_args(*args)
        args = "-f #{OpsPreflight.root_path('data', 'deploy.rb')}"

        # mina's --verbose doesn't work
        args << ' -v' if options[:verbose]

        [:simulate, :trace].each do |opt|
          args << " --#{opt.to_s}" if options[opt]
        end

        args
      end
    end
  end
end
