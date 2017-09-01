module Daru
  module IO
    class << self
      # Loading and writing Marshalled DataFrame/Vector
      def save klass, filename
        fp = File.open(filename, 'w')
        Marshal.dump(klass, fp)
        fp.close
      end

      def load filename
        return false unless File.exist? filename
        o = false
        File.open(filename, 'r') { |fp| o = Marshal.load(fp) }
        o
      end
    end
  end
end
