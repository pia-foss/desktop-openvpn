# openvpn24-client

This repository builds the OpenVPN 2.4 client for use in desktop.

Since this repository uses submodules, make sure to include `--recursive` when cloning it.  If you forgot, `git submodule update --init` will initialize the submodules.

## Submodules and patches

`openvpn` and `openvpn-build` are included as submodules, and PIA-specific changes are stored as patch files in this repository.

This makes updating the upstream dependencies simple, and makes it easier to keep track of the PIA changes (so we don't lose anything on updates, and so we can see what changes we need to specifically test).

| Submodule | Platform | Patch directory |
|-----------|----------|-----------------|
| openvpn   | Any      | patch-openvpn   |
| openvpn-build | Windows | patch-openvpn-build-windows |
| openvpn-build | Mac/Linux | patch-openvpn-build-posix |

## Working on module patches

The workflow for working on the patches themselves is somewhat more complex, but should not cause too much pain once you get the hang of it.

For simple changes, feel free to edit the patches manually (make sure to adjust line counts).  For more complex changes, you can turn the patches into Git commits on the current OpenVPN version, edit the submodule normally, then regenerate patches.

In the procedure below, do everything from the submodule directory (and in bash on Windows); except for the full build in step 5, which is done from the openvpn24-client root.

1. Create a work branch in the submodule
   * `git checkout -B my-work-branch` (create a new branch on current HEAD, name doesn't matter because you won't push it)
2. Apply patches
   * `git am ../patch-openvpn-build-windows/*.patch`
3. Delete patches
   * Delete these so the build process won't apply them again (you'll regenerate them later)
   * `rm ../patch-openvpn-build/*.patch`
4. Make changes and commit to submodule
   * Commit author & message matter; these will go into the patch files
   * You can make any changes you want, including rewriting/squashing/amending the commits generated from the patches
5. Test build
   * From the project root, with your changes committed in the submodules:
     * Windows: Run `build-pia.bat`
     * Mac/Linux: Run `build-posix`
   * Repeat 4+5 as many times as you need to
6. Regenerate patches
   * `git format-patch -o ../patch-openvpn-build-windows/ v2.4.7`, where `v2.4.7` is the original commit that this submodule was on
7. Revert submodule to original commit
   * `git checkout v2.4.7` (or whatever version OpenVPN was on)
  
You can now check in your changes to the patches (and/or build-pia.bat, etc.)

The submodule itself should not show any changes in the openvpn24-client repo's `git status`, since it's on the same commit that it was on initially.

## Updating OpenVPN

1. `cd` into the submodule
2. `git fetch` and and `git checkout <new_version>`
3. `cd` back to `openvpn24-client`
4. Test build to make sure the patches still apply
   - If they don't update and regenerate them using the procedure above; resolve merge conflicts as necessary.
   - Commit the patch updates and submodule update together (since they probably depend on each other).
5. The submodule should show a change to the new commit; commit this to `openvpn24-client`

This procedure applies to both `openvpn` and `openvpn-build`.  The two submodules may have to be updated together if they contain dependent changes.
