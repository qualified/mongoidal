# 0.3.0
- Added GitHub Actions CI: Mongoid 7.4 / 8.0 / 8.1 x Ruby 3.0 / 3.2 against mongo:7.0
- Verified compatibility with Mongoid 8.0 and 8.1
- Fixed BulkSavable#bulk_assign NameError when no embeds are given
- Fixed Nesting#nested_save! argument forwarding on Ruby 3
- Loosened dev dependencies (mongoid >= 7.4, < 8.2; dropped bundler ~> 1.6)
# 0.2.6
- Upgraded Mongoid to 7.4.x
# 0.2.5
- Upgraded nested_assign to work with Mongoid 7.x
# 0.2.4
- Removed macro method references
# 0.2.3
- StringifiedSymbol -> Mongoid::StringifiedSymbol
# 0.2.2
- Additional StringifiedSymbol support for enum and tag fields
# 0.2.1
- Now use StringifiedSymbol when possible
- Ensure revisions are sorted properly when restoring
- Removed Permittable module, not used and had upgrade issues

# 0.2.0
- Revision#restore! now does a full restore of changes to that point, and saves as a new revision, instead of removing old history 

# 0.1.14
- RevisableBase#max_revision_number method optimized
- revision associations are no longer validated

# 0.1.13
- ExternalRevisions are now properly saved when calling revise!