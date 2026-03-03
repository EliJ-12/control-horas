// Test script for auto time registration logic
import { AutoTimeScheduler } from '../server/scheduler.js';

// Mock database and settings for testing
const mockSettings = [
  {
    id: 1,
    userId: 1,
    enabled: true,
    monday: true,
    tuesday: true,
    wednesday: true,
    thursday: true,
    friday: true,
    saturday: false,
    sunday: false,
    startTime: "09:00",
    endTime: "14:00",
    autoRegisterTime: "14:05",
    createdAt: new Date(),
    updatedAt: new Date()
  }
];

// Test the day checking logic
function testDayChecking() {
  console.log('Testing day checking logic...');
  
  const scheduler = new AutoTimeScheduler();
  
  // Test different days
  const testCases = [
    { day: 1, expected: true, description: 'Monday (should register)' },
    { day: 2, expected: true, description: 'Tuesday (should register)' },
    { day: 3, expected: true, description: 'Wednesday (should register)' },
    { day: 4, expected: true, description: 'Thursday (should register)' },
    { day: 5, expected: true, description: 'Friday (should register)' },
    { day: 6, expected: false, description: 'Saturday (should not register)' },
    { day: 0, expected: false, description: 'Sunday (should not register)' }
  ];
  
  testCases.forEach(({ day, expected, description }) => {
    const result = scheduler.shouldRegisterForDay(mockSettings[0], day);
    console.log(`${description}: ${result === expected ? '✅ PASS' : '❌ FAIL'} (got ${result}, expected ${expected})`);
  });
}

// Test time checking logic
function testTimeChecking() {
  console.log('\nTesting time checking logic...');
  
  const scheduler = new AutoTimeScheduler();
  
  const testCases = [
    { time: "14:05", expected: true, description: 'Exact match time (should register)' },
    { time: "14:06", expected: false, description: 'One minute after (should not register)' },
    { time: "14:04", expected: false, description: 'One minute before (should not register)' },
    { time: "09:00", expected: false, description: 'Start time (should not register)' }
  ];
  
  testCases.forEach(({ time, expected, description }) => {
    const result = scheduler.isTimeToRegister(mockSettings[0].autoRegisterTime, time);
    console.log(`${description}: ${result === expected ? '✅ PASS' : '❌ FAIL'} (got ${result}, expected ${expected})`);
  });
}

// Test work log creation logic
function testWorkLogCreation() {
  console.log('\nTesting work log creation logic...');
  
  const scheduler = new AutoTimeScheduler();
  
  // Test valid time range
  const validSettings = {
    ...mockSettings[0],
    startTime: "09:00",
    endTime: "14:00"
  };
  
  console.log('Valid time range (09:00-14:00): Should create 300 minutes (5 hours)');
  
  // Test invalid time range
  const invalidSettings = {
    ...mockSettings[0],
    startTime: "14:00",
    endTime: "09:00"
  };
  
  console.log('Invalid time range (14:00-09:00): Should not create work log');
}

// Test complete scenario
function testCompleteScenario() {
  console.log('\nTesting complete scenario...');
  
  // Simulate Monday at 14:05
  const mockDate = new Date();
  mockDate.setDay(1); // Monday
  mockDate.setHours(14, 5, 0, 0);
  
  const currentTime = mockDate.toTimeString().slice(0, 5); // "14:05"
  const currentDay = mockDate.getDay(); // 1 (Monday)
  
  const scheduler = new AutoTimeScheduler();
  
  const shouldRegister = scheduler.shouldRegisterForDay(mockSettings[0], currentDay) && 
                        scheduler.isTimeToRegister(mockSettings[0].autoRegisterTime, currentTime);
  
  console.log(`Monday at 14:05 with settings (Mon-Fri, 09:00-14:00, register at 14:05):`);
  console.log(`Should register: ${shouldRegister ? '✅ YES' : '❌ NO'}`);
  
  if (shouldRegister) {
    console.log('✅ Auto registration would trigger correctly');
  } else {
    console.log('❌ Auto registration would not trigger');
  }
}

// Run all tests
console.log('🧪 Running Auto Time Registration Tests\n');
testDayChecking();
testTimeChecking();
testWorkLogCreation();
testCompleteScenario();
console.log('\n✨ Tests completed!');
