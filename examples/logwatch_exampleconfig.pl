use Function::Parameters ':strict';

+{
  logfile=> "logwatch_example.log",
  match=> fun ($line) {
      $line=~ /yes/
  },
  collecttime=> 4,
  report=> fun ($path) {
      print "== REPORT: ======= \n";
      system "cat",$path;
      print "================== \n";
      unlink $path;
  },
 }
