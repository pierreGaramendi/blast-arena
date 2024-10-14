import React, { useState, useEffect } from 'react';

export const GameMenu: React.FC = () => {
  const [selectedOption, setSelectedOption] = useState(0);
  const menuOptions = ['Normal Game', 'Battle Game', 'Options'];

  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'ArrowUp') {
        setSelectedOption((prev) => (prev > 0 ? prev - 1 : menuOptions.length - 1));
      } else if (event.key === 'ArrowDown') {
        setSelectedOption((prev) => (prev < menuOptions.length - 1 ? prev + 1 : 0));
      }
    };

    window.addEventListener('keydown', handleKeyDown);

    return () => {
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [menuOptions.length]);

  const handleSelect = (index: number) => {
    setSelectedOption(index);
    console.log(`Selected: ${menuOptions[index]}`);
  };

  return (
    <div className="flex h-screen items-center justify-center bg-gray-800">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-white mb-8">BLAST ARENA</h1>
        <ul className="space-y-4">
          {menuOptions.map((option, index) => (
            <li
              key={index}
              onClick={() => handleSelect(index)}
              className={`cursor-pointer text-2xl ${
                selectedOption === index ? 'text-yellow-400 font-bold' : 'text-white'
              }`}
            >
              {option}
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};