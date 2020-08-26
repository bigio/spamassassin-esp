Mail::SpamAssassin::Plugin::Esp

SpamAssassin plugin for Invaluement.com Service Provider DNSBLs ("SPBL").

The plugin doesn't download the data feed, the txt file should be downloaded using
"curl -z" or "wget -N" that only downloads the file when the server versions are newer.
