package extlib_config;

use Cwd 'abs_path';
use File::Spec::Functions ('catpath', 'splitpath');
my $PATH = (splitpath(abs_path $0))[0, 1];
sub Config {
    {
        path => $PATH,
        modspec_file => "${PATH}etc/modules.yaml",
        mirror_meta_file => "${PATH}etc/extlib.json",
        cpanm_executable => "${PATH}cpanm",
        last_run_file => "${PATH}var/last-install-results.json",
    }
}
