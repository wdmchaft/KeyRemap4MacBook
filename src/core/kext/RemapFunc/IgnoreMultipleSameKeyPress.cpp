#include "IgnoreMultipleSameKeyPress.hpp"

namespace org_pqrs_KeyRemap4MacBook {
  namespace RemapFunc {
    void
    IgnoreMultipleSameKeyPress::initialize(void)
    {
      lastkeycode_ = KeyCode::VK_NONE;
    }

    void
    IgnoreMultipleSameKeyPress::terminate(void)
    {}

    void
    IgnoreMultipleSameKeyPress::add(KeyCode newval)
    {
      fromKey_.key = newval;
    }

    void
    IgnoreMultipleSameKeyPress::add(Flags newval)
    {
      fromKey_.flags = newval;
    }

    bool
    IgnoreMultipleSameKeyPress::remap(RemapParams& remapParams)
    {
      if (remapParams.isremapped || ! FlagStatus::makeFlags().isOn(fromKey_.flags)) {
        lastkeycode_ = KeyCode::VK_NONE;
        return false;
      }

      if (fromKey_.key == remapParams.params.key &&
          fromKey_.key == lastkeycode_) {
        // disable event.
        remapParams.isremapped = true;
        return true;
      }

      // set lastkeycode_ if KeyUp.
      if (! remapParams.isKeyDownOrModifierDown()) {
        lastkeycode_ = remapParams.params.key;
      }
      return false;
    }
  }
}