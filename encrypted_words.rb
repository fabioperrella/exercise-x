def find_encrypted_string(s)
  # Write your code here
  s_size = s.size
  if s_size <= 2
    return s
  end

  middle = s_size / 2
  if s_size.even?
    middle -= 1
  end

  s[middle] + find_encrypted_string(s[0..middle-1]) + find_encrypted_string(s[middle+1..-1])
end

def check(expected, output)
  if expected != output
    puts "failed: #{expected} != #{output}"
  else
    puts 'ok'
  end
end

result = find_encrypted_string("")
check(result, "")

result = find_encrypted_string("a")
check(result, "a")

result = find_encrypted_string("ab")
check(result, "ab")

result = find_encrypted_string("abc")
check(result, "bac")

result = find_encrypted_string("abcd")
check(result, "bacd")

result = find_encrypted_string("gsd76gf7gs")
check(result, "6sgd77gfgs")
