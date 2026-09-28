ExUnit.start()

# Compatibility shim: the modules that still read through Memoize call into the
# cached ones heightless, and a heightless read needs a head. One default head
# for the whole suite keeps them passing until they are migrated too - remove
# this once every module reads through `Rujira.Cache`, and let each case set
# its own head through `Rujira.Test.CacheCase`.
:ok = Rujira.Test.CacheCase.reset!()
