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