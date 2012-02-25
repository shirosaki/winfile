require "rubygems"
gem "minitest"
require "minitest/spec"
require "minitest/autorun"
require "fileutils"
require "tmpdir"

require "winfile"
include WinFile

describe WinFile do
  let(:long_name) { "This is a directory with a long name" }

  before :each do
    @pwd = Dir.pwd
    @tmp_dir = Dir.mktmpdir("long_path_test")
    Dir.chdir @tmp_dir

    Dir.mkdir long_name
    @dir_name = File.dirname(File.expand_path(long_name))
    output = `cmd.exe /C DIR /X`
    output.force_encoding("BINARY") if output.respond_to? :force_encoding
    @short_name = output.split.find { |o| o =~ /^THISIS/ }
  end

  after :each do
    Dir.chdir @pwd
    FileUtils.rm_rf @tmp_dir
  end

  it "converts a base name to long name" do
    long_path(@short_name).must_equal long_name
    long_path("#{@dir_name}/#{@short_name}").must_equal "#{@dir_name}/#{long_name}"
    File.expand_path("#{@dir_name}/#{@short_name}").must_equal "#{@dir_name}/#{long_name}"
  end
  
  it "remains the same with existing path" do
    long_path(long_name).must_equal long_name
    long_path("#{@dir_name}/#{long_name}").must_equal "#{@dir_name}/#{long_name}"
    File.expand_path("#{@dir_name}/#{long_name}").must_equal "#{@dir_name}/#{long_name}"
  end
  
  it "remains the same with non-existing path" do
    long_path("dummy").must_equal "dummy"
    long_path("#{@dir_name}/dummy").must_equal "#{@dir_name}/dummy"
    File.expand_path("#{@dir_name}/dummy").must_equal "#{@dir_name}/dummy"
  end

  if /cygwin/ =~ RUBY_PLATFORM
    describe "cygwin plain file symlink" do
      let(:long_symlink) { "a symlink with a long name" }

      before :each do
         `ln -s "#{long_name}" "#{long_symlink}"`
         output = `cmd.exe /C DIR /X /AS`
         output.force_encoding("BINARY") if output.respond_to? :force_encoding
         @short_symlink = output.split.find { |o| o =~ /^ASYMLI/ }
      end

      after :each do
        FileUtils.rm_rf @short_symlink
      end

      it "converts a symlink to long name" do
        long_path(@short_symlink).must_equal long_symlink
        long_path("#{@dir_name}/#{@short_symlink}").must_equal "#{@dir_name}/#{long_symlink}"

        # This spec fails. Base name remains short.
        # File.expand_path("#{@dir_name}/#{@short_symlink}").must_equal "#{@dir_name}/#{long_symlink}"
      end

      it "remains the same with existing long name symlink" do
        long_path(long_symlink).must_equal long_symlink
        long_path("#{@dir_name}/#{long_symlink}").must_equal "#{@dir_name}/#{long_symlink}"
        File.expand_path("#{@dir_name}/#{long_symlink}").must_equal "#{@dir_name}/#{long_symlink}"
      end
    end

    describe "cygwin symlink as Windows shortcuts" do
      let(:long_symlink) { "a symlink with a long name" }

      before :each do
         old_env = ENV["CYGWIN"]
         ENV["CYGWIN"] = "winsymlinks"
         `ln -s "#{long_name}" "#{long_symlink}"`
         output = `cmd.exe /C DIR /X`
         output.force_encoding("BINARY") if output.respond_to? :force_encoding
         @short_symlink_with_lnk = output.split.find { |o| o =~ /^ASYMLI/ }
         @short_symlink = @short_symlink_with_lnk.sub(/\.lnk$/i, "")
         ENV["CYGWIN"] = old_env
      end

      after :each do
        FileUtils.rm_rf @short_symlink_with_lnk
      end

      it "converts a shortcut symlink to long name" do
        long_path(@short_symlink).must_equal long_symlink
        long_path("#{@dir_name}/#{@short_symlink}").must_equal "#{@dir_name}/#{long_symlink}"
      end

      it "converts a shortcut symlink with extention to long name" do
        long_path(@short_symlink_with_lnk).must_equal "#{long_symlink}.lnk"
        long_path("#{@dir_name}/#{@short_symlink_with_lnk}").must_equal "#{@dir_name}/#{long_symlink}.lnk"
      end

      it "remains the same with existing long name shortcut symlink" do
        long_path(long_symlink).must_equal long_symlink
        long_path("#{long_symlink}.lnk").must_equal "#{long_symlink}.lnk"
        long_path("#{@dir_name}/#{long_symlink}").must_equal "#{@dir_name}/#{long_symlink}"
      end
    end
  end
end
