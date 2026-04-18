#pragma once

#include <TargetConditionals.h>
#include <AuthenticationServices/AuthenticationServices.h>

#include "gdextension_interface.h"
#include "godot_cpp/core/defs.hpp"
#include "godot_cpp/classes/node.hpp"
#include "godot_cpp/core/class_db.hpp"
#include "godot_cpp/variant/string.hpp"
#include "godot_cpp/variant/utility_functions.hpp"

namespace godot {
class One: public Node {
  GDCLASS(One, Node);
protected:
  static void _bind_methods();
  
public:
  One();
  ~One();
  bool start_session(const String &url, const String &scheme);
};
}
