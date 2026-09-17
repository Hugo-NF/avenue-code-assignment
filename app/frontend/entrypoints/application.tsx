import { createInertiaApp } from '@inertiajs/react'

createInertiaApp({
  pages: '../pages',

  strictMode: true,

  defaults: {
    form: {
      forceIndicesArrayFormatInFormData: false,
      withAllErrors: true,
    },
    visitOptions: () => {
      return { queryStringArrayFormat: 'brackets' }
    },
  },
}).catch((error) => {
  if (document.getElementById('app')) {
    throw error
  } else {
    console.error(
      'Missing root element.\n\n' +
      'If you see this error, it probably means you loaded Inertia.js on non-Inertia pages.\n' +
      'Consider moving <%= vite_javascript_tag "application.tsx" %> to the Inertia-specific layout instead.',
    )
  }
})
