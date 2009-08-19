Gem::Specification.new do |s|
  s.name = %q{stompserver}
  s.version = "0.9.9.2009081900"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lionel Bouton"]
  s.date = %q{2009-08-19}
  s.default_executable = %q{stompserver}
  s.description = %q{Stomp messaging server with file/dbm/memory/activerecord based FIFO
queues, queue monitoring, and basic authentication.

== SYNOPSYS:

Handles basic message queue processing}
  s.email = ["lionel-dev@bouton.name"]
  s.executables = ["stompserver"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt", "client/README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "STATUS", "bin/stompserver", "client/README.txt", "client/both.rb", "client/consume.rb", "client/send.rb", "config/stompserver.conf", "etc/passwd.example", "lib/stomp_server.rb", "lib/stomp_server/protocols/http.rb", "lib/stomp_server/protocols/stomp.rb", "lib/stomp_server/queue.rb", "lib/stomp_server/queue/activerecord_queue.rb", "lib/stomp_server/queue/ar_message.rb", "lib/stomp_server/queue/dbm_queue.rb", "lib/stomp_server/queue/file_queue.rb", "lib/stomp_server/queue/memory_queue.rb", "lib/stomp_server/queue_manager.rb", "lib/stomp_server/stomp_auth.rb", "lib/stomp_server/stomp_frame.rb", "lib/stomp_server/stomp_id.rb", "lib/stomp_server/stomp_user.rb", "lib/stomp_server/test_server.rb", "lib/stomp_server/topic_manager.rb", "setup.rb", "test/tesly.rb", "test/test_queue_manager.rb", "test/test_stomp_frame.rb", "test/test_topic_manager.rb", "test_todo/test_stomp_server.rb"]
  s.homepage = %q{    by Patrick Hurley, Lionel Bouton}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{stompserver}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A very light messaging server}
  s.test_files = ["test/test_topic_manager.rb", "test/test_stomp_frame.rb", "test/test_queue_manager.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<daemons>, [">= 1.0.2"])
      s.add_runtime_dependency(%q<eventmachine>, [">= 0.7.2"])
      s.add_runtime_dependency(%q<hoe>, [">= 1.1.1"])
      s.add_development_dependency(%q<hoe>, [">= 2.3.2"])
    else
      s.add_dependency(%q<daemons>, [">= 1.0.2"])
      s.add_dependency(%q<eventmachine>, [">= 0.7.2"])
      s.add_dependency(%q<hoe>, [">= 1.1.1"])
      s.add_dependency(%q<hoe>, [">= 2.3.2"])
    end
  else
    s.add_dependency(%q<daemons>, [">= 1.0.2"])
    s.add_dependency(%q<eventmachine>, [">= 0.7.2"])
    s.add_dependency(%q<hoe>, [">= 1.1.1"])
    s.add_dependency(%q<hoe>, [">= 2.3.2"])
  end
end
