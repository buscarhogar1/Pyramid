import "./styles.css";

export default function PrivacyPolicy() {
  const updated = "July 18, 2026";

  return (
    <main className="page">
      <article className="policy">
        <p className="eyebrow">Pyramid - Drinking Game</p>
        <h1>Privacy Policy</h1>
        <p className="updated">Last updated: {updated}</p>

        <section>
          <h2>Overview</h2>
          <p>
            Pyramid - Drinking Game does not collect, share, sell, or transmit
            personal data to any server.
          </p>
        </section>

        <section>
          <h2>Data Stored on Your Device</h2>
          <p>
            The app may store gameplay preferences locally on your device, such
            as selected language and player names entered during a game. This
            information stays on the device and is used only to support gameplay
            and remember preferences.
          </p>
        </section>

        <section>
          <h2>Data Collection and Sharing</h2>
          <p>
            The app does not use account creation, advertising SDKs, analytics
            SDKs, third-party cookies, location, contacts, camera, microphone,
            payment data, or external user tracking.
          </p>
        </section>

        <section>
          <h2>Retention and Deletion</h2>
          <p>
            Locally stored preferences remain on the device until the user
            changes them, clears app data, or uninstalls the app.
          </p>
        </section>

        <section>
          <h2>Contact</h2>
          <p>
            For privacy questions, please use the developer contact email shown
            on the Google Play Store listing for Pyramid - Drinking Game.
          </p>
        </section>

        <hr />

        <h1>Politica de Privacidad</h1>
        <p className="updated">Ultima actualizacion: {updated}</p>

        <section>
          <h2>Resumen</h2>
          <p>
            Pyramid - Drinking Game no recopila, comparte, vende ni transmite
            datos personales a ningun servidor.
          </p>
        </section>

        <section>
          <h2>Datos guardados en el dispositivo</h2>
          <p>
            La app puede guardar preferencias de juego localmente en tu
            dispositivo, como el idioma seleccionado y los nombres de jugadores
            introducidos durante una partida. Esta informacion permanece en el
            dispositivo y se usa solo para el funcionamiento del juego y para
            recordar preferencias.
          </p>
        </section>

        <section>
          <h2>Recopilacion y uso compartido</h2>
          <p>
            La app no usa cuentas, SDKs de publicidad, SDKs de analitica,
            cookies de terceros, ubicacion, contactos, camara, microfono, datos
            de pago ni seguimiento externo de usuarios.
          </p>
        </section>

        <section>
          <h2>Conservacion y eliminacion</h2>
          <p>
            Las preferencias guardadas localmente permanecen en el dispositivo
            hasta que el usuario las cambie, borre los datos de la app o
            desinstale la app.
          </p>
        </section>

        <section>
          <h2>Contacto</h2>
          <p>
            Para consultas de privacidad, usa el correo de contacto del
            desarrollador indicado en la ficha de Google Play de Pyramid -
            Drinking Game.
          </p>
        </section>
      </article>
    </main>
  );
}
