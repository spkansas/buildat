#pragma once
#include "core/types.h"

#define EXPORT __attribute__ ((visibility ("default")))

namespace interface
{
	struct Event;

	struct Module
	{
		virtual ~Module(){};
		virtual void event(const interface::Event &event) = 0;
	};
}