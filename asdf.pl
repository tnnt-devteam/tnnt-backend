
my $foo = [(0) x 100];
for (my $i = 0; $i < 100; $i++) {
    push @$foo, (0) x 100;
}
for (my $i = 0; $i < 100; $i++) {
    for (my $j = 0; $j < 100; $j++) {
        $foo->[$i][$j] = $i * $j;
    }
}
print $foo->[53][20] . "\n";