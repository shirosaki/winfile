require "winfile/version"

module WinFile
  if RUBY_VERSION < '1.9.1'
    require 'Win32API'
  else
    require 'dl'
    class Win32API
      DLL = {}
      TYPEMAP = {"0" => DL::TYPE_VOID, "S" => DL::TYPE_VOIDP, "I" => DL::TYPE_LONG}

      def initialize(dllname, func, import, export = "0", calltype = :stdcall)
        @proto = [import].join.tr("VPpNnLlIi", "0SSI").sub(/^(.)0*$/, '\1')
        handle = DLL[dllname] ||= DL.dlopen(dllname)
        @func = DL::CFunc.new(handle[func], TYPEMAP[export.tr("VPpNnLlIi", "0SSI")], func, calltype)
      end

      def call(*args)
        import = @proto.split("")
        args.each_with_index do |x, i|
          args[i], = [x == 0 ? nil : x].pack("p").unpack("l!*") if import[i] == "S"
          args[i], = [x].pack("I").unpack("i") if import[i] == "I"
        end
        ret, = @func.call(args)
        return ret || 0
      end

      alias Call call
    end
  end

  GetLongPathName = Win32API.new(*%w"kernel32 GetLongPathName PPI I")

  # Convert path to long format name
  def long_path(name)
    name = name.dup
    if (len = GetLongPathName.call(name, nil, 0)).nonzero?
      buf = "\0" * len
      buf[0...GetLongPathName.call(name, buf, buf.size)]
    else
      name
    end
  end

  if /cygwin/ =~ RUBY_PLATFORM
    CCP_POSIX_TO_WIN_A = 0 # from is char*, to is char*
    CCP_POSIX_TO_WIN_W = 1 # from is char*, to is wchar_t*
    CCP_WIN_A_TO_POSIX = 2 # from is char*, to is char*
    CCP_WIN_W_TO_POSIX = 3 # from is wchar_t*, to is char*

    # Or these values to the above as needed.
    CCP_ABSOLUTE = 0       # Request absolute path (default).
    CCP_RELATIVE = 0x100   # Request to keep path relative.

    begin
      Cygwin_conv_path = Win32API.new(*%w"cygwin1.dll cygwin_conv_path IPPI I")
    rescue RuntimeError
      Cygwin_conv_to_win32_path = Win32API.new(*%w"cygwin1.dll cygwin_conv_to_win32_path PP I")
    end

    def cygwin_conv_path_to_win32_path(path)
      if Cygwin_conv_path
        if (len = Cygwin_conv_path.call(CCP_POSIX_TO_WIN_A | CCP_RELATIVE, path, nil, 0)) >= 0
          buf = "\0" * len
          Cygwin_conv_path.call(CCP_POSIX_TO_WIN_A | CCP_RELATIVE, path, buf, buf.size)
          buf = buf[0...-1]
        end
      else
        buf = "\0" * 1024
        if Cygwin_conv_to_win32_path.call(path, buf) == 0
          buf.delete!("\0")
          buf
        end
      end
    end

    alias long_path_win long_path

    # Convert basename to long format name
    def long_path(name)
      is_shortcut = false
      has_lnk = false
      if File.symlink? name
        has_lnk = true if name =~ /\.lnk$/
        is_shortcut = true if has_lnk || File.exists?(name + ".lnk")
      end

      dir_name = File.dirname(name)
      buf = nil
      if dir_name == "."
        dir_name = nil unless name[0] == "."
        buf = name.dup
      elsif (buf = cygwin_conv_path_to_win32_path(dir_name))
        buf << "\\" << File.basename(name)
      else
        raise "cygwin_conv_path error"
      end

      if is_shortcut && !has_lnk
        buf << ".lnk"
      end

      win_path = long_path_win(buf)

      result = nil
      if dir_name
        result = File.join(dir_name, File.basename(win_path))
      else
        result = win_path
      end

      if is_shortcut && !has_lnk
        result.sub!(/\.lnk$/, "")
      end

      result
    end
  end
  module_function :long_path
end if /cygwin|mswin|mingw/ =~ RUBY_PLATFORM
