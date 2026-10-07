/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        tcs: {
          blue: '#1b4d89',
          navy: '#0e2b4f',
          header: '#2c3e50',
          bg: '#e9ecef',
          panel: '#f5f7fa',
          border: '#ced4da',
          notVisited: '#e2e8f0', // silver/white
          notAnswered: '#dc2626', // red
          answered: '#16a34a', // green
          marked: '#7c3aed', // purple
          markedAnswered: '#7c3aed', // purple with green tick
        }
      },
      fontFamily: {
        sans: ['Inter', 'Noto Sans Devanagari', 'Segoe UI', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
