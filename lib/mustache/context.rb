require 'mustache/context_miss'
require 'mustache/key_finder'

class Mustache
  class FrameTracker
    attr_accessor :frame

    def initialize frame
      self.frame = frame
    end

    def update new_frame
      self.frame = new_frame
    end

    def fetch(key, default)
      self.frame.fetch key, default
    end
  end

  class ContextFrame
    attr_accessor :object, :previous_frame, :current_view

    def initialize object, previous_frame
      self.object = object
      self.previous_frame = previous_frame

      if object.is_a?(Mustache)
        self.current_view = object
      else
        self.current_view = previous_frame.current_view
      end
    end

    def fetch(key, default)
      KeyFinder.find(self.object, key, default)
    end

    def frame_tracker
      @frame_tracker ||= self.previous_frame.frame_tracker
    end

    def current_view= view
      @current_view = view
      view.frame_tracker = self.frame_tracker
    end
  end

  class ContextRootFrame < ContextFrame
    def initialize object
      self.object = object

      self.current_view = object
    end

    def frame_tracker
      @frame_tracker ||= FrameTracker.new(self)
    end
  end

  # A Context represents the context which a Mustache template is
  # executed within. All Mustache tags reference keys in the Context.
  #
  class Context
    attr_accessor :frame

    # Initializes a Mustache::Context.
    #
    # @param [Any] ctx Initial context.
    # @param [Mustache] view A Mustache instance.
    #
    def initialize(ctx, view)
      if !ctx.is_a? ContextFrame
        ctx = ContextFrame.new(ctx, ContextRootFrame.new(view))
      end

      self.frame = ctx
    end

    # A {{>partial}} tag translates into a call to the context's
    # `render_partial` method, which would be this sucker right here.
    #
    # The partial is looked up in the current Mustache view. This
    # view is also responsible for rendering the result.
    #
    def render_partial(name, indentation = '')
      # Indent the partial template by the given indentation.
      partial_template = current_view.partial(name).to_s.gsub(/^/, indentation)

      current_view.render(partial_template, self.frame)
    end

    # Allows customization of how Mustache escapes things.
    #
    # @param [String] str String to escape.
    #
    # @return [String] Escaped HTML string.
    #
    def escape(str)
      current_view.escapeHTML(str)
    end

    # Adds a new object to the context's internal stack.
    #
    # @param [Object] new_obj Object to be added to the internal stack.
    #
    # @return [Context] Returns the Context.
    #
    def push(new_obj)
      self.frame = ContextFrame.new(new_obj, self.frame)
    end

    # Removes the most recently added object from the context's
    # internal stack.
    #
    # @return [Context] Returns the Context.
    #
    def pop
      self.frame = frame.previous_frame
    end

    # Alias for `fetch`.
    def [](name)
      fetch(name, nil)
    end

    # Similar to Hash#fetch, finds a value by `name` in the context's
    # stack. You specify the default return value by passing a
    # second parameter.
    #
    # If raise_on_context_miss is set to true, this will raise a ContextMiss exception on miss.
    def fetch(name, default)
      current_frame = self.frame

      while current_frame
        value = current_frame.fetch(name, :__missing)

        return value if value != :__missing

        current_frame = current_frame.previous_frame
      end

      if current_view.raise_on_context_miss?
        raise ContextMiss.new("Can't find #{name} in context stack")
      else
        default
      end
    end

    def find(obj, key)
      KeyFinder.find(obj, key, nil)
    end

    def current
      frame.object
    end


    private

    # Change current frame.
    #
    # This notifies the frame tracker every time a frame change occurs.
    # This is related to the frame_tracker hack
    def frame= frame
      @frame = frame
      frame.frame_tracker.update(frame)
    end

    # Find the first Mustache in the stack.
    #
    # If we're being rendered inside a Mustache object as a context,
    # we'll use that one.
    #
    # @return [Mustache] First Mustache in the stack.
    #
    def current_view
      frame.current_view
    end
  end
end
