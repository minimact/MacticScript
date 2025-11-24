// Counter.tsx - Test component for Minimact transpiler
import { useState, useEffect, useRef } from '@minimact/core';

export function Counter() {
  const [count, setCount] = useState(0);
  const buttonRef = useRef(null);

  useEffect(() => {
    console.log(`Count changed to: ${count}`);
  }, [count]);

  const increment = () => {
    setCount(count + 1);
  };

  return (
    <div className="counter">
      <h1>Counter</h1>
      <p>Count: {count}</p>
      <button ref={buttonRef} onClick={increment}>
        Increment
      </button>
    </div>
  );
}
