#! /usr/bin/perl -w


$cur = "";
$lastX = 0;
$lastY = 0;
$lastCX = 0;
$lastCY = 0;
$indent = ' ' x 8;
@vals = ();

sub printCommandsForD($);

while (<STDIN>) {
  chomp;
  my ($name, $d) = split /\t/, $_;
  print "    \"$name\": { (p: CGMutablePath) -> () in\n";
  printCommandsForD($d);
  print "    },\n"
}

sub parseNumbers($) {
  my $n = $_[0];
  @vals = ();
  for (my $i = 0; $i < $n; $i++) {
    if (!(($cur =~ s/^[\s,]*([\+\-]?\d*\.?\d*(?:[eEfF][\+\-]?\d+)?)//))) {
      die "missing number ($cur)"
    }
    my $number = $1;
    if ($number =~ /^-?\./) {
      $number =~ s/\./0./
    }
    push(@vals, $number);
  }
}


sub convertRelativeValsToAbsolute() {
  for (my $i = 0; $i < scalar(@vals); $i++) {
    $vals[$i] += ($i % 2 == 0) ? $lastX : $lastY;
  }
}

sub prependControlPoint() {
  unshift(@vals, 2 * $lastX - $lastCX, 2 * $lastY - $lastCY);
}

sub updateLast() {
  $lastY = pop(@vals);
  $lastX = pop(@vals);
  if (scalar(@vals) == 0) {
    $lastCX = $lastX;
    $lastCY = $lastY;
  } else {
    $lastCY = pop(@vals);
    $lastCX = pop(@vals);
  }
}

sub pr_pathCommand($$) {
  my ($cmd, $args) = @_;
  print $indent . $cmd . "(p, nil, " . join(', ', @$args) . ")\n";
}

sub printCommandsForD($) {
  $cur = $_[0];
  $lastX = 0;
  $lastY = 0;
  $lastCX = 0;
  $lastCY = 0;
  $lastCmd = '';

  while ($cur ne '') {
    $cur =~ s/^\s+//;
    my $cmd = substr($cur, 0, 1);
    if ($cmd =~ /^[\.\-\+\d]$/) {
      $cmd = $lastCmd;
    } else {
      $cur = substr($cur, 1);
      $lastCmd = $cmd;
    }
    if ($cmd eq 'M') {
      parseNumbers(2);
      pr_pathCommand("CGPathMoveToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 'm') {
      parseNumbers(2);
      convertRelativeValsToAbsolute();
      pr_pathCommand("CGPathMoveToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 'L') {
      parseNumbers(2);
      convertRelativeValsToAbsolute();
      pr_pathCommand("CGPathAddLineToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 'l') {
      parseNumbers(2);
      convertRelativeValsToAbsolute();
      pr_pathCommand("CGPathAddLineToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 'H') {
      parseNumbers(1);
      $lastX = $vals[0];
      pr_pathCommand("CGPathAddLineToPoint", [$lastX, $lastY]);
      $lastCX = $lastX;
      $lastCY = $lastY;
    } elsif ($cmd eq 'h') {
      parseNumbers(1);
      $lastX += $vals[0];
      pr_pathCommand("CGPathAddLineToPoint", [$lastX, $lastY]);
      $lastCX = $lastX;
      $lastCY = $lastY;
    } elsif ($cmd eq 'V') {
      parseNumbers(1);
      $lastY = $vals[0];
      pr_pathCommand("CGPathAddLineToPoint", [$lastX, $lastY]);
      $lastCX = $lastX;
      $lastCY = $lastY;
    } elsif ($cmd eq 'v') {
      parseNumbers(1);
      $lastY += $vals[0];
      pr_pathCommand("CGPathAddLineToPoint", [$lastX, $lastY]);
      $lastCX = $lastX;
      $lastCY = $lastY;
    } elsif ($cmd eq 'Q') {
      parseNumbers(4);
      pr_pathCommand("CGPathAddQuadCurveToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 'q') {
      parseNumbers(4);
      convertRelativeValsToAbsolute();
      pr_pathCommand("CGPathAddQuadCurveToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 'T') {
      parseNumbers(2);
      prependControlPoint();
      pr_pathCommand("CGPathAddQuadCurveToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 't') {
      parseNumbers(2);
      convertRelativeValsToAbsolute();
      prependControlPoint();
      pr_pathCommand("CGPathAddQuadCurveToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 'C') {
      parseNumbers(6);
      pr_pathCommand("CGPathAddCurveToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 'c') {
      parseNumbers(6);
      convertRelativeValsToAbsolute();
      pr_pathCommand("CGPathAddCurveToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 'S') {
      parseNumbers(4);
      prependControlPoint();
      pr_pathCommand("CGPathAddCurveToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 's') {
      parseNumbers(4);
      convertRelativeValsToAbsolute();
      prependControlPoint();
      pr_pathCommand("CGPathAddCurveToPoint", \@vals);
      updateLast();
    } elsif ($cmd eq 'z' || $cmd eq 'Z') {
      print "${indent}CGPathCloseSubpath(p)\n";
    } else {
      print STDERR "unrecognized command: $cmd\n";
      exit(1);
    }


    # TODO: a, A
  }
}
