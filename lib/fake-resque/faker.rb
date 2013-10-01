require 'delegate'

module FakeResque
  module Faker
    def fake_push(queue, item)
      if @forward
        payload = decode(encode(item))
        job=Resque::Job.new(queue, payload)
        begin
          job.perform
        rescue Object=>e
          job.fail(e)

          if FakeResque.raise_errors?
            raise e
          end
        end
      end
    end

    def fake_enqueue_to(queue, klass, *args)
      klass.perform *args
    end

    def block!
      @forward = false
    end

    def unblock!
      @forward = true
    end

    def start_faking!
      replace :push, with: :fake_push
      replace :enqueue_to, with: :fake_enqueue_to
    end

    def stop_faking!
      replace :push, with: :real_push
      replace :enqueue_to, with: :real_enqueue_to
    end

    def replace(that, opts)
      (class<< self;self;end).class_eval "alias_method :#{that}, :#{opts.fetch(:with)}"
    end

    def self.extended(klass)
      klass.class_eval "alias_method :real_push, :push"
      klass.class_eval "alias_method :real_enqueue_to, :enqueue_to"
    end
  end
end
