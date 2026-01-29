-- TestFramework.lua
-- Comprehensive test framework with verbose logging capabilities
-- Provides utilities for running tests, assertions, mocking, and detailed logging
-- Place in ServerStorage/DevOnly

local TestFramework = {}
TestFramework.__index = TestFramework

-- Log levels
TestFramework.LogLevel = {
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
	NONE = 5
}

-- Default log level
TestFramework.currentLogLevel = TestFramework.LogLevel.DEBUG

-- Test status
TestFramework.Status = {
	PASS = "PASS",
	FAIL = "FAIL",
	SKIP = "SKIP",
	ERROR = "ERROR"
}

-- Test result tracking
TestFramework.testResults = {
	passed = {},
	failed = {},
	skipped = {},
	errors = {}
}

-- Statistics
TestFramework.stats = {
	totalTests = 0,
	passedTests = 0,
	failedTests = 0,
	skippedTests = 0,
	errorTests = 0,
	totalAssertions = 0,
	passedAssertions = 0,
	failedAssertions = 0,
	startTime = 0,
	endTime = 0
}

-- Current test context
TestFramework.currentTest = nil
TestFramework.currentSuite = nil

--------------------------------------------------------------------------------
-- Logging Functions
--------------------------------------------------------------------------------

function TestFramework:log(level, message, ...)
	if level < self.currentLogLevel then
		return
	end
	
	local levelNames = {
		[self.LogLevel.DEBUG] = "[DEBUG]",
		[self.LogLevel.INFO] = "[INFO]",
		[self.LogLevel.WARN] = "[WARN]",
		[self.LogLevel.ERROR] = "[ERROR]"
	}
	
	local prefix = levelNames[level] or "[LOG]"
	local timestamp = os.date("%H:%M:%S")
	
	local formattedMessage = string.format(message, ...)
	print(string.format("[%s] %s %s", timestamp, prefix, formattedMessage))
end

function TestFramework:debug(message, ...)
	self:log(self.LogLevel.DEBUG, message, ...)
end

function TestFramework:info(message, ...)
	self:log(self.LogLevel.INFO, message, ...)
end

function TestFramework:warn(message, ...)
	self:log(self.LogLevel.WARN, message, ...)
end

function TestFramework:error(message, ...)
	self:log(self.LogLevel.ERROR, message, ...)
end

function TestFramework:setLogLevel(level)
	self.currentLogLevel = level
	self:info("Log level set to: %s", level)
end

--------------------------------------------------------------------------------
-- Assertion Functions
--------------------------------------------------------------------------------

function TestFramework:assert(condition, message)
	self.stats.totalAssertions = self.stats.totalAssertions + 1
	
	if condition then
		self.stats.passedAssertions = self.stats.passedAssertions + 1
		self:debug("✓ Assertion passed: %s", message or "condition is true")
		return true
	else
		self.stats.failedAssertions = self.stats.failedAssertions + 1
		local errorMsg = message or "Assertion failed"
		self:error("✗ Assertion failed: %s", errorMsg)
		error(errorMsg, 2)
	end
end

function TestFramework:assertEqual(actual, expected, message)
	local msg = message or string.format("Expected %s, got %s", tostring(expected), tostring(actual))
	return self:assert(actual == expected, msg)
end

function TestFramework:assertNotEqual(actual, expected, message)
	local msg = message or string.format("Expected value not to be %s", tostring(expected))
	return self:assert(actual ~= expected, msg)
end

function TestFramework:assertNil(value, message)
	local msg = message or string.format("Expected nil, got %s", tostring(value))
	return self:assert(value == nil, msg)
end

function TestFramework:assertNotNil(value, message)
	local msg = message or string.format("Expected non-nil value, got nil")
	return self:assert(value ~= nil, msg)
end

function TestFramework:assertTrue(value, message)
	local msg = message or string.format("Expected true, got %s", tostring(value))
	return self:assert(value == true, msg)
end

function TestFramework:assertFalse(value, message)
	local msg = message or string.format("Expected false, got %s", tostring(value))
	return self:assert(value == false, msg)
end

function TestFramework:assertType(value, expectedType, message)
	local actualType = type(value)
	local msg = message or string.format("Expected type %s, got %s", expectedType, actualType)
	return self:assert(actualType == expectedType, msg)
end

function TestFramework:assertInstanceOf(value, className, message)
	local isInstance = typeof(value) == "Instance" and value:IsA(className)
	local msg = message or string.format("Expected instance of %s, got %s", className, typeof(value))
	return self:assert(isInstance, msg)
end

function TestFramework:assertGreaterThan(actual, threshold, message)
	local msg = message or string.format("Expected %s > %s", tostring(actual), tostring(threshold))
	return self:assert(actual > threshold, msg)
end

function TestFramework:assertLessThan(actual, threshold, message)
	local msg = message or string.format("Expected %s < %s", tostring(actual), tostring(threshold))
	return self:assert(actual < threshold, msg)
end

function TestFramework:assertTableContains(tbl, value, message)
	for _, v in pairs(tbl) do
		if v == value then
			local msg = message or string.format("Table contains value: %s", tostring(value))
			self:debug("✓ %s", msg)
			return true
		end
	end
	
	local msg = message or string.format("Table does not contain value: %s", tostring(value))
	self:error("✗ %s", msg)
	error(msg, 2)
end

function TestFramework:assertArrayLength(array, expectedLength, message)
	local actualLength = #array
	local msg = message or string.format("Expected array length %d, got %d", expectedLength, actualLength)
	return self:assert(actualLength == expectedLength, msg)
end

--------------------------------------------------------------------------------
-- Test Suite Management
--------------------------------------------------------------------------------

function TestFramework:createSuite(name)
	self:info("═══════════════════════════════════════════════════════════")
	self:info("Creating test suite: %s", name)
	self:info("═══════════════════════════════════════════════════════════")
	
	local suite = {
		name = name,
		tests = {},
		beforeEach = nil,
		afterEach = nil,
		beforeAll = nil,
		afterAll = nil
	}
	
	return suite
end

function TestFramework:runTest(suite, testName, testFunc)
	self.currentSuite = suite.name
	self.currentTest = testName
	self.stats.totalTests = self.stats.totalTests + 1
	
	self:info("")
	self:info("─────────────────────────────────────────────────────────")
	self:info("Running test: %s.%s", suite.name, testName)
	self:info("─────────────────────────────────────────────────────────")
	
	local testStartTime = os.clock()
	local status = self.Status.PASS
	local errorMessage = nil
	
	-- Run beforeEach hook
	if suite.beforeEach then
		self:debug("Running beforeEach hook...")
		local success, err = pcall(suite.beforeEach)
		if not success then
			self:error("beforeEach hook failed: %s", tostring(err))
			status = self.Status.ERROR
			errorMessage = "beforeEach failed: " .. tostring(err)
		end
	end
	
	-- Run the test
	if status == self.Status.PASS then
		local success, err = pcall(testFunc)
		
		if success then
			status = self.Status.PASS
			self:info("✓ Test PASSED: %s", testName)
			self.stats.passedTests = self.stats.passedTests + 1
			table.insert(self.testResults.passed, {
				suite = suite.name,
				test = testName,
				duration = os.clock() - testStartTime
			})
		else
			status = self.Status.FAIL
			errorMessage = tostring(err)
			self:error("✗ Test FAILED: %s", testName)
			self:error("Error: %s", errorMessage)
			self.stats.failedTests = self.stats.failedTests + 1
			table.insert(self.testResults.failed, {
				suite = suite.name,
				test = testName,
				error = errorMessage,
				duration = os.clock() - testStartTime
			})
		end
	end
	
	-- Run afterEach hook
	if suite.afterEach then
		self:debug("Running afterEach hook...")
		local success, err = pcall(suite.afterEach)
		if not success then
			self:error("afterEach hook failed: %s", tostring(err))
		end
	end
	
	local testDuration = os.clock() - testStartTime
	self:info("Test duration: %.3f seconds", testDuration)
	
	return status, errorMessage
end

function TestFramework:runSuite(suite)
	self:info("")
	self:info("╔═══════════════════════════════════════════════════════════╗")
	self:info("║ Running Test Suite: %-37s║", suite.name)
	self:info("╚═══════════════════════════════════════════════════════════╝")
	
	-- Run beforeAll hook
	if suite.beforeAll then
		self:info("Running beforeAll hook...")
		local success, err = pcall(suite.beforeAll)
		if not success then
			self:error("beforeAll hook failed: %s", tostring(err))
			return
		end
	end
	
	-- Run all tests
	for testName, testFunc in pairs(suite.tests) do
		self:runTest(suite, testName, testFunc)
	end
	
	-- Run afterAll hook
	if suite.afterAll then
		self:info("Running afterAll hook...")
		local success, err = pcall(suite.afterAll)
		if not success then
			self:error("afterAll hook failed: %s", tostring(err))
		end
	end
	
	self:info("")
	self:info("Completed test suite: %s", suite.name)
end

--------------------------------------------------------------------------------
-- Test Result Reporting
--------------------------------------------------------------------------------

function TestFramework:generateReport()
	local duration = self.stats.endTime - self.stats.startTime
	
	self:info("")
	self:info("╔═══════════════════════════════════════════════════════════╗")
	self:info("║                     TEST SUMMARY REPORT                   ║")
	self:info("╚═══════════════════════════════════════════════════════════╝")
	self:info("")
	
	-- Test statistics
	self:info("Test Execution Statistics:")
	self:info("  Total Tests Run:    %d", self.stats.totalTests)
	self:info("  Tests Passed:       %d (%.1f%%)", self.stats.passedTests, 
		self.stats.totalTests > 0 and (self.stats.passedTests / self.stats.totalTests * 100) or 0)
	self:info("  Tests Failed:       %d (%.1f%%)", self.stats.failedTests,
		self.stats.totalTests > 0 and (self.stats.failedTests / self.stats.totalTests * 100) or 0)
	self:info("  Tests Skipped:      %d", self.stats.skippedTests)
	self:info("  Tests with Errors:  %d", self.stats.errorTests)
	self:info("")
	
	-- Assertion statistics
	self:info("Assertion Statistics:")
	self:info("  Total Assertions:   %d", self.stats.totalAssertions)
	self:info("  Passed Assertions:  %d (%.1f%%)", self.stats.passedAssertions,
		self.stats.totalAssertions > 0 and (self.stats.passedAssertions / self.stats.totalAssertions * 100) or 0)
	self:info("  Failed Assertions:  %d (%.1f%%)", self.stats.failedAssertions,
		self.stats.totalAssertions > 0 and (self.stats.failedAssertions / self.stats.totalAssertions * 100) or 0)
	self:info("")
	
	-- Timing information
	self:info("Execution Time:")
	self:info("  Total Duration:     %.3f seconds", duration)
	self:info("  Average per Test:   %.3f seconds", 
		self.stats.totalTests > 0 and (duration / self.stats.totalTests) or 0)
	self:info("")
	
	-- Failed tests detail
	if #self.testResults.failed > 0 then
		self:info("Failed Tests:")
		for i, failure in ipairs(self.testResults.failed) do
			self:info("  %d. %s.%s", i, failure.suite, failure.test)
			self:info("     Error: %s", failure.error)
			self:info("     Duration: %.3f seconds", failure.duration)
		end
		self:info("")
	end
	
	-- Overall result
	local overallStatus = self.stats.failedTests == 0 and "✓ ALL TESTS PASSED" or "✗ SOME TESTS FAILED"
	local statusSymbol = self.stats.failedTests == 0 and "✓" or "✗"
	
	self:info("═══════════════════════════════════════════════════════════")
	self:info("%s Overall Status: %s", statusSymbol, overallStatus)
	self:info("═══════════════════════════════════════════════════════════")
	
	return self.stats.failedTests == 0
end

function TestFramework:reset()
	self:debug("Resetting test framework...")
	
	self.testResults = {
		passed = {},
		failed = {},
		skipped = {},
		errors = {}
	}
	
	self.stats = {
		totalTests = 0,
		passedTests = 0,
		failedTests = 0,
		skippedTests = 0,
		errorTests = 0,
		totalAssertions = 0,
		passedAssertions = 0,
		failedAssertions = 0,
		startTime = 0,
		endTime = 0
	}
	
	self.currentTest = nil
	self.currentSuite = nil
end

--------------------------------------------------------------------------------
-- Mock and Stub Utilities
--------------------------------------------------------------------------------

function TestFramework:createMock(className)
	self:debug("Creating mock for: %s", className)
	
	local mock = {
		__className = className,
		__calls = {},
		__returnValues = {}
	}
	
	function mock:__index(key)
		return function(...)
			table.insert(self.__calls, {method = key, args = {...}})
			return self.__returnValues[key]
		end
	end
	
	setmetatable(mock, mock)
	return mock
end

function TestFramework:expectCalled(mock, methodName, times)
	local callCount = 0
	for _, call in ipairs(mock.__calls) do
		if call.method == methodName then
			callCount = callCount + 1
		end
	end
	
	if times then
		self:assertEqual(callCount, times, 
			string.format("Expected %s to be called %d times, but was called %d times", 
				methodName, times, callCount))
	else
		self:assertGreaterThan(callCount, 0,
			string.format("Expected %s to be called at least once", methodName))
	end
end

return TestFramework
