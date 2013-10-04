use inc::Module::Install;

name     'Lingua-JA-NormalizeText';
all_from 'lib/Lingua/JA/NormalizeText.pm';

requires 'Carp';
requires 'Exporter';
requires 'Unicode::Normalize'           => 1.00;
requires 'HTML::Entities'               => 3.66;
requires 'HTML::Scrubber'               => 0.09;
requires 'Lingua::JA::Regular::Unicode' => 0.11;
requires 'Lingua::JA::Dakuon';

test_requires 'Test::More' => 0.88; # done_testing
test_requires 'Test::Base';
test_requires 'Test::Fatal';
test_requires 'Test::Warn' => 0.20;

tests 't/*.t';
author_tests 'xt';

readme_from 'lib/Lingua/JA/NormalizeText.pm';

resources(
    license    => 'http://dev.perl.org/licenses',
    repository => 'https://github.com/pawa-/Lingua-JA-NormalizeText',
    bugtracker => 'https://github.com/pawa-/Lingua-JA-NormalizeText/issues',
);

WriteAll;
