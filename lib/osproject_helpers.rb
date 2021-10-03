# @!method _gsub_file
#   Conducts a regex substition on a file.  Replaces every match,
#   Takes either a replacement string or a block to pass to String.gsub!
def _gsub_file(path, match, replace=nil, &block)
  content = File.read(path)
  if (replace == nil && block == nil) || (replace != nil && block != nil)
    raise
  elsif replace
    content.gsub!(match, replace)
  elsif block
    content.gsub!(match, &block)
  end
  srcfile = File.open(path, 'w')
  srcfile.write(content)
  srcfile.close
end

# @!method _sub_file
#   Conducts a regex substition on a file.  Only replaces on the first match,
#   Takes either a replacement string or a block to pass to String.sub!
def _sub_file(path, match, replace=nil, &block)
  content = File.read(path)
  result = nil
  if (replace == nil && block == nil) || (replace != nil && block != nil)
    raise
  elsif replace
    result = content.sub!(match, replace)
  elsif block
    result = content.sub!(match, &block)
  end
  srcfile = File.open(path, 'w')
  srcfile.write(content)
  srcfile.close
  return result
end

# @!method _insert_lines
#   Insert line, or array of lines, after a given marker.  Will insert at the same indent level.
def _insert_lines(file, match, insert)
  if insert.is_a? Array
    return _sub_file(file, /^(\s*)(#{match})/) do |line|
      indent = $1 || ''
      puts "indent: ", indent.length
      prevln = $2 || ''
      puts "prevln: ", prevln
      retline = line + "\n" + indent + insert.join("\n" + indent) + "\n"
      puts "retline: ", retline
      return retline 
    end
  else
    return _sub_file(file, /^(\s*)(#{match})/, '\1\2' + "\n" + '\1' + insert)
  end
end
