import * as React from 'react';
import { StyleSheet, View, Button, Text, Image } from 'react-native';
import ImagesToVideo from 'react-native-images-to-video';
import RNFS from 'react-native-fs';
import data from './images';
import Share from 'react-native-share';

export default function App() {
  const [absolutePaths, setAbsolutePaths] = React.useState<Array<string>>([]);

  React.useEffect(() => {
    const timer = setTimeout(() => {
      const promises = data.images.map((record, index) => {
        return writeBase64ImageToSandbox(`${index}.jpg`, record.data);
      });

      (async () => {
        try {
          const absolutePaths = await Promise.all(promises);

          setAbsolutePaths(absolutePaths);
        } catch (err) {
          console.log(err);
        }
      })();
    }, 500);

    return () => {
      clearTimeout(timer);
    };
  }, []);

  return (
    <View style={styles.container}>
      {absolutePaths.length === 0 ? (
        <Text>Loading data...</Text>
      ) : (
        <React.Fragment>
          <Button disabled={!absolutePaths} title="Video from Images (3s per image)" onPress={async () => {
            Image.getSize(
              absolutePaths[0], // Use the first image to inform the width, height.
              async (width, height) => {
                const videoURL = await ImagesToVideo.render({
                  fileName: 'My Video',
                  screenTimePerImage: 3,
                  width,
                  height,
                  absolutePaths
                });

                console.log(videoURL);

                const res = await Share.open({
                  title: 'Video File',
                  message: 'Check out the video!',
                  url: videoURL,
                });
                console.log(res);
              },
              (err) => {
                console.log(err);
              },
            );
          }} />
          <Button disabled={!absolutePaths} title="Video from Images (2/3s per image)" onPress={async () => {
            Image.getSize(
              absolutePaths[0], // Use the first image to inform the width, height.
              async (width, height) => {
                const videoURL = await ImagesToVideo.render({
                  fileName: 'My Video',
                  screenTimePerImage: 2 / 3,
                  width,
                  height,
                  absolutePaths
                });

                console.log(videoURL);

                const res = await Share.open({
                  title: 'Video File',
                  message: 'Check out the video!',
                  url: videoURL,
                });
                console.log(res);
              },
              (err) => {
                console.log(err);
              },
            );
          }} />
          <Button disabled={!absolutePaths} title="Video from Images (0.333s per image)" onPress={async () => {
            Image.getSize(
              absolutePaths[0], // Use the first image to inform the width, height.
              async (width, height) => {
                const videoURL = await ImagesToVideo.render({
                  fileName: 'My Video',
                  screenTimePerImage: 0.333,
                  width,
                  height,
                  absolutePaths
                });

                console.log(videoURL);

                const res = await Share.open({
                  title: 'Video File',
                  message: 'Check out the video!',
                  url: videoURL,
                });
                console.log(res);
              },
              (err) => {
                console.log(err);
              },
            );
          }} />
        </React.Fragment>
      )}
    </View>
  );
}

const writeBase64ImageToSandbox = async (fileName: string, base64Data: string): Promise<string> => {
  const dest = `${RNFS.TemporaryDirectoryPath}${fileName}`;

  await RNFS.writeFile(dest, base64Data, 'base64');

  return dest;
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
