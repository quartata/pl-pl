#!/usr/bin/perl
# pl

use List::Util reduce;
use feature qw(say switch);

%variables = ();
%commands = (
  7=>\(sub { return shift(@_)*shift(@_) }), # multiplication
  15=>\(sub { return 2*pop; }),             # double
  19=>\(sub { return factorial(pop); }),    # factorial
  30=>\(sub { $variables{$lastusedvar} = \(deref($variables{$lastusedvar})+1); return; }), # increment last var
  31=>\(sub { $variables{$lastusedvar} = \(deref($variables{$lastusedvar})-1); return; }), # decrement last var
  61=>\(sub {                               # assignment
      $pointer++;
      @variables{@tokens[$pointer]} = \pop;
      return;
  }),
  135=>\(sub { $n = shift(@_); $k = shift(@_); return (factorial($n)/(factorial($k)*factorial($n-$k))); }), # combinations
  171=>\(sub { return 0.5*pop; }), # half
  196=>\(sub { return shift(@_)-shift(@_); }), # subtraction
  197=>\(sub { return shift(@_)+shift(@_); }), # addition
  240=>\(sub { return isPrime(pop); }),        # primality
  244=>\(sub { $x = pop(@arguments); $y = pop(@arguments); push(@arguments,$x); push(@arguments,$y); return; }), # swap
  245=>\(sub { @arguments = reverse(@arguments); }), # reverse
  246=>\(sub { return shift(@_)/shift(@_); }), # division
  252=>\(sub { return shift(@_)**shift(@_); }) # exponent
);
%arities = (
  7=>2,
  15=>1,
  19=>1,
  30=>0,
  31=>0,
  61=>1,
  135=>2,
  171=>1,
  196=>2,
  197=>2,
  240=>1,
  244=>0,
  245=>0,
  246=>2,
  252=>2
);
@tokens = ();
@arguments = ();
$pointer = 0;
$lastusedvar = "_";

given(<>) {
  @tokens = split("",$_);
  $variables{"_"} = \<STDIN>; # i can't believe this works
  for(;$pointer < scalar(@tokens);$pointer++) {
    $token = @tokens[$pointer];
    $code = ord($token);
    if($code >= 48 and $code <= 57) { # beginning of a numeral
      push(@arguments,stringParse(3));
    } elsif($code >= 33 and $code <= 126 and $code != 61 and $code != 34 and $code != 39) {
      $ref = $variables{$token};
      if(exists($variables{$token})) {
        push(@arguments,deref($ref)); # push variable
        $lastusedvar = $token;
      } else {
        push(@arguments,stringParse(1)); # implict string
      }
    } else {
      if(exists($commands{$code})) { # command
        $arity = $arities{$code};
        @needed = ();
        for($counter = $arity;$counter > 0 and scalar(@arguments) > 0;$counter--) {
          push(@needed,shift(@arguments)); # pop the arguments we need
        }
        if(scalar(@needed) + 1 == $arity) {
          push(@needed,deref($variables{"_"})); # add default var if we're off by one
        } elsif(scalar(@needed) < $arity) {
          continue; # give up if we don't have enough
        }
        $result = &{deref($commands{$code})}(@needed);
        if(defined($result)) { 
          push(@arguments,$result); # place result on stack
        }
      } else {
        if($code == 34) { # regular string
          $pointer++;
          push(@arguments,stringParse(0));
        } elsif($code == 39) { # one char string
          $pointer++;
          push(@arguments,stringParse(2));
        }
      }
    }
  }
  if(scalar(@arguments) == 0) { 
    print deref($variables{"_"}); # print default var if the stack is empty
  } else {
    print join("",@arguments); # print stack otherwise
  }
}


# mode 0 is regular strings
# mode 1 is implict strings
# mode 2 is one-char strings
# mode 3 is numerals
sub stringParse {
  my @string = ();
  my $mode = pop;
  if($mode == 1) {
    while(ord(@tokens[$pointer]) >= 33 and ord(@tokens[$pointer]) <= 126 and @tokens[$pointer] ne '"' and !exists($variables{@tokens[$pointer]}) and $pointer < scalar(@tokens)) {
      push(@string, @tokens[$pointer]);
      $pointer++;
    }
    if(@tokens[$pointer] ne '"') { $pointer--; }
  } elsif($mode == 0) {
    while(@tokens[$pointer] ne '"' and $pointer < scalar(@tokens)) {
      push(@string, @tokens[$pointer]);
      $pointer++; 
    }
  } elsif($mode == 2) {
    push(@string, @tokens[$pointer]);
  } elsif($mode == 3) {
    while(ord(@tokens[$pointer]) >= 48 and ord(@tokens[$pointer]) <= 57) {
      push(@string, @tokens[$pointer]);
      $pointer++;
    }
    $pointer--;
  }
  return join("",@string);
}


# handy function for dereferencing
# we use this quite a bit since we need to use references to store non-scalars
# in a hash
sub deref {
  my $ref = pop;
  my $type = ref $ref;
  if($type == "SCALAR") {
    return $$ref;
  } elsif($type == "ARRAY") {
    return @$ref;
  } elsif($type == "HASH") {
    return %$ref;
  } else {
    return &$ref;
  }
}

sub factorial {
  if(@_[0] == 0) { return 1; }
  return reduce(sub {$a * $b}, 1..pop);
}

# lazy trial division up to sqrt(n)
# replace with something that doesn't suck later
sub isPrime {
  $num = shift(@_);
  $s = int(sqrt($num));
  if($num <= 2) { return ($num == 2 ? 1 : 0); } 
  for($c = 2; $c <= $s; $c++) {
    if(($num % $c) == 0) { return 0; }
  }
  return 1;
}