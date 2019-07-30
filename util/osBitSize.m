function str = osBitSize()

  [~, maxArraySize] = computer();
  if maxArraySize > 2^31
    str             = '64';
  else
    str             = '32';
  end

end
