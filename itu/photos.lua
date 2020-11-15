local f = {};
f.a = 1;

function f:wow(a)
  print(self.a, a);
end

function f.wow(self, a)
  print(self.a, a);
end

f["wow"] = function(self, a)
  print(self.a, a);
end

f:wow(2) 
f.wow(f, 2)