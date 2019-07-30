%% Creates a struct with fields corresponding to public properties of the given class object.
function s = class2struct(c)

  s               = struct();
  for field = properties(c)'
    s.(field{:})  = c.(field{:});
  end

end
